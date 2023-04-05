import 'package:collection/collection.dart';
import 'package:cron/cron.dart';
import 'package:pvpc_server/tools/price_zone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

import 'models/price_average.dart';
import 'models/price_per_hour.dart';
import 'tools/http_wrapper.dart';
import 'tools/logger.dart';
import 'tools/round_to_double_precision.dart';

class PriceWatcher {
  static final Map<String, PriceWatcher> _cache = <String, PriceWatcher>{};
  final List<PricePerHour> _prices = [];
  final List<PriceAverage> _priceAverages = [];
  final _logger = LoggerWrapper().logger;
  final cron = Cron();
  late Location location;

  factory PriceWatcher() {
    return _cache.putIfAbsent('httpWrapper', () => PriceWatcher._internal());
  }
  PriceWatcher._internal();

  List<PriceAverage> get priceAverages {
    return _priceAverages;
  }

  List<PricePerHour> get prices {
    return _prices;
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    location = getLocation('Europe/Madrid');

    //populate prices
    await _populatePriceData();

    //schedule crons
    /* 
    This cronjob will get the price data every day at 20:30 (Madrid time)
    */
    cron.schedule(Schedule.parse('30 20 * * *'), () async {
      //default timezone for docker-compose.yml is Europe/Madrid as well
      _logger.i('cron: get price for next day');
      await _getPricesFromAPI(
        TZDateTime.now(location).add(Duration(days: 1)),
      );
    });

    /* 
    This cronjob cleans up the data table, every day at 21:00 (Madrid time)
    */
    cron.schedule(Schedule.parse('0 21 * * *'), () async {
      final oneDayAgo = TZDateTime.now(location).subtract(Duration(days: 1));
      _logger.i('cron: removing data before day ${oneDayAgo.day}');
      _logger.d('cron: _prices before: ${_prices.length}');
      _logger.d('cron: _priceAverages before: ${_priceAverages.length}');

      _prices.removeWhere(
        (element) => element.time.isBefore(oneDayAgo),
      );
      _priceAverages.removeWhere(
        (element) => element.time.isBefore(oneDayAgo),
      );

      _logger.d('cron: _prices after: ${_prices.length}');
      _logger.d('cron: _priceAverages after: ${_priceAverages.length}');
    });
  }

  Future<Map<String, dynamic>> _getDataFromAPI({
    required String startTime,
    required String endTime,
    required String zone,
  }) async {
    try {
      return await HttpWrapper().get(
        requestJson: true,
        path:
            '/datos/mercados/precios-mercados-tiempo-real?start_date=$startTime&end_date=$endTime&time_trunc=hour&geo_limit=$zone',
      );
    } catch (e) {
      _logger.e(
        'getDataFromAPI: Unable to get prices from API. Shutting down...',
      );
      throw Exception(e.toString());
    }
  }

  Future<void> _getPricesFromAPI(DateTime dateTime) async {
    final isoDate = dateTime.toIso8601String().split('T')[0];
    final daytMidnight = '${isoDate}T00:00';
    final dayAt2359 = '${isoDate}T23:59';

    if (_prices
            .firstWhereOrNull((element) => element.time.day == dateTime.day) !=
        null) {
      _logger.w(
        'getPricesFromAPI: data already exists for day ${dateTime.day}',
      );
      return;
    }

    //loop through pricezones, get the respective prices and update their averages
    for (var zone in PriceZone.values) {
      _logger.i('getPricesFromAPI: for $isoDate in ${zone.name}');

      _parseApiResult(
        res: await _getDataFromAPI(
          startTime: daytMidnight,
          endTime: dayAt2359,
          zone: zone.name,
        ),
        zone: zone,
      );
      //populate price averages
      _updatePriceAverage(time: dateTime, zone: zone);

      //rate each hourly price
      final average = _priceAverages.firstWhere(
        (element) => element.time.day == dateTime.day && element.zone == zone,
      );

      for (PricePerHour pricePerHour in _prices.where(
        (element) =>
            element.time.day == dateTime.day &&
            element.time.month == dateTime.month &&
            element.zone == zone,
      )) {
        final priceLevelInPercent = roundDoubleToPrecision(
          (pricePerHour.priceInEUR / average.averagePriceInEUR) * 100,
          2,
        );

        if (priceLevelInPercent > 90) {
          //10% margin filter
          pricePerHour.rating = PriceRating.peak;
        } else {
          pricePerHour.rating = PriceRating.offPeak;
        }
        pricePerHour.priceRelativeToDayAverageInPercent = priceLevelInPercent;
        _logger.d(
          'getPricesFromAPI added ${pricePerHour.toString()} in ${zone.name}',
        );
      }
    }
  }

  _parseApiResult({
    required Map<String, dynamic> res,
    required PriceZone zone,
  }) {
    final List included = res["included"];
    bool found1001 = false;

    //find PVPC with group id 1001
    for (var element in included) {
      if (element['id'] == '1001') {
        found1001 = true;
        final Map<String, dynamic> attributes = element['attributes'];
        final List values = attributes['values'];

        for (var value in values) {
          var priceInCents = roundDoubleToPrecision(value['value'] / 1000, 5);
          _prices.add(
            PricePerHour(
              time: TZDateTime.parse(location, value['datetime']),
              priceInEUR: priceInCents,
              zone: zone,
            ),
          );
        }
      }
    }
    if (found1001 == false) {
      _logger.e(
        'parseApiResult: PVPC not included in result. Shutting down...',
      );
      throw Exception();
    }
  }

  Future<void> _populatePriceData() async {
    final now = TZDateTime.now(location);
    await _getPricesFromAPI(now); //TODAY

    if (now.hour >= 20 && now.hour <= 23) {
      //check if init happened between 20 and 23 -> cron might not have run -> get tomorrows data
      if (now.hour == 20 && now.minute < 30) {
        //don't fetch before 20:30
        return;
      }

      await _getPricesFromAPI(
        now.add(Duration(days: 1)),
      );
    }
  }

  void _updatePriceAverage({required DateTime time, required PriceZone zone}) {
    final List<double> pricesForRelevantDay = [];
    for (PricePerHour pricePerHour in _prices) {
      final timeOfPrice = pricePerHour.time;
      if (pricePerHour.zone == zone &&
          timeOfPrice.day == time.day &&
          timeOfPrice.month == time.month) {
        pricesForRelevantDay.add(pricePerHour.priceInEUR);
      }
    }

    final averagePriceInEUR = roundDoubleToPrecision(
      pricesForRelevantDay.average,
      5,
    );

    _priceAverages.add(
      PriceAverage(
        time: DateTime(time.year, time.month, time.day),
        zone: zone,
        averagePriceInEUR: averagePriceInEUR,
      ),
    );

    _logger.i('updatePriceAverage ${zone.name} $averagePriceInEUR');
  }
}
