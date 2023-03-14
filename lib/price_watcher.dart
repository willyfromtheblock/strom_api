import 'package:collection/collection.dart';
import 'package:cron/cron.dart';
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
    cron.schedule(Schedule.parse('30 20 * * *'), () async {
      //default timezone for docker-compose.yml is Europe/Madrid as well
      _logger.i('cron: get price for next day');
      await _getPricesFromAPI(
        TZDateTime.now(location).add(Duration(days: 1)),
      );
    });

    cron.schedule(Schedule.parse('0 21 * * *'), () async {
      final oneDayAgo = TZDateTime.now(location).subtract(Duration(days: 1));
      _logger.i('cron: removing data before day ${oneDayAgo.day}');
      _logger.i('cron: _prices before: ${_prices.length}');
      _logger.i('cron: _priceAverages before: ${_priceAverages.length}');

      _prices.removeWhere(
        (element) => element.time.isBefore(oneDayAgo),
      );
      _priceAverages.removeWhere(
        (element) => element.time.isBefore(oneDayAgo),
      );

      _logger.i('cron: _prices after: ${_prices.length}');
      _logger.i('cron: _priceAverages after: ${_priceAverages.length}');
    });
  }

  Future<Map<String, dynamic>> _getDataFromAPI({
    required String startTime,
    required String endTime,
  }) async {
    try {
      return await HttpWrapper().get(
        requestJson: true,
        path:
            '/datos/mercados/precios-mercados-tiempo-real?start_date=$startTime&end_date=$endTime&time_trunc=hour',
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

    _logger.i('getPricesFromAPI: for $isoDate');
    _parseApiResult(
      await _getDataFromAPI(
        startTime: daytMidnight,
        endTime: dayAt2359,
      ),
    );
    _updatePriceAverage(dateTime);
    final average = _priceAverages.firstWhere(
      (element) => element.time == dateTime,
    );

    for (PricePerHour pricePerHour in _prices) {
      final priveLevelInPercent = roundDoubleToPrecision(
          (pricePerHour.priceInEUR / average.averagePriceInEUR) * 100, 2);
      if (priveLevelInPercent > 90) {
        //10% margin filter
        pricePerHour.rating = PriceRating.peak;
      } else {
        pricePerHour.rating = PriceRating.offPeak;
      }
      pricePerHour.priceRelativeToDayAverageInPercent = priveLevelInPercent;
      _logger.i(
        'getPricesFromAPI added ${pricePerHour.toString()}',
      );
    }
  }

  _parseApiResult(Map<String, dynamic> res) {
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
          final newPPH = PricePerHour(
            time: TZDateTime.parse(location, value['datetime']),
            priceInEUR: priceInCents,
          );
          _prices.add(newPPH);
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

  void _updatePriceAverage(DateTime time) {
    final List<double> pricesForRelevantDay = [];
    for (PricePerHour pricePerHour in _prices) {
      final timeOfPrice = pricePerHour.time;
      if (timeOfPrice.day == time.day &&
          timeOfPrice.month == time.month &&
          timeOfPrice.year == time.year) {
        pricesForRelevantDay.add(pricePerHour.priceInEUR);
      }
    }

    _priceAverages.add(
      PriceAverage(
        time: time,
        averagePriceInEUR: roundDoubleToPrecision(
          pricesForRelevantDay.average,
          5,
        ),
      ),
    );
    for (var element in _priceAverages) {
      _logger.i('updatePriceAverage ${element.toString()}');
    }
  }
}
