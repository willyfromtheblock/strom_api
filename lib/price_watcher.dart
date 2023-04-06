import 'dart:io';

import 'package:collection/collection.dart';
import 'package:cron/cron.dart';
import 'package:strom_api/price_api_wrappers/api_wrapper_es.dart';
import 'package:strom_api/tools/price_zone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

import 'models/price_average.dart';
import 'models/price_per_hour.dart';
import 'tools/logger.dart';
import 'tools/round_to_double_precision.dart';

class PriceWatcher {
  static final Map<String, PriceWatcher> _cache = <String, PriceWatcher>{};
  final List<PricePerHour> _prices = [];
  final List<PriceAverage> _priceAverages = [];
  final _logger = LoggerWrapper().logger;
  final _cron = Cron();
  late Location _location;

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
    _location = getLocation('Europe/Madrid');

    //populate prices
    await _populatePriceData();

    //schedule crons
    /* 
    This cronjob will get the price data every day at 20:30 (Madrid time) for the Spanish API
    */
    _cron.schedule(Schedule.parse('30 20 * * *'), () async {
      //default timezone for docker-compose.yml is Europe/Madrid as well
      _logger.i('cron: get price for next day');
      await _getPricesFromAPI(
        TZDateTime.now(_location).add(Duration(days: 1)),
      );
    });

    /* 
    This cronjob cleans up the data table, every day at 21:00 (Madrid time)
    */
    _cron.schedule(Schedule.parse('0 21 * * *'), () async {
      final oneDayAgo = TZDateTime.now(_location).subtract(Duration(days: 1));
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

  Future<void> _getPricesFromAPI(DateTime dateTime) async {
    final isoDate = dateTime.toIso8601String().split('T')[0];
    final dayAtMidnight = '${isoDate}T00:00';
    final dayAt2359 = '${isoDate}T23:59';

    //loop through pricezones, get the respective prices and update their averages
    for (var zone in PriceZone.values) {
      if (_prices.firstWhereOrNull(
            (element) =>
                element.time.day == dateTime.day && element.zone == zone,
          ) !=
          null) {
        _logger.w(
          'getPricesFromAPI: data already exists for day ${dateTime.day} in ${zone.name}',
        );
        return;
      }

      _logger.i('getPricesFromAPI: for $isoDate in ${zone.name}');
      List<PricePerHour> results = [];

      switch (zone) {
        case PriceZone.peninsular:
        case PriceZone.canarias:
        case PriceZone.baleares:
        case PriceZone.ceuta:
        case PriceZone.melilla:
        default:
          results = await APIWrapperES().fetchData(
            startTime: dayAtMidnight,
            endTime: dayAt2359,
            zone: zone,
            location: _location,
          );
      }
      //add fetched prices
      _prices.addAll(results);

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

        if (priceLevelInPercent >
            100 -
                int.parse(
                  Platform.environment['RATING_MARGIN']!,
                )) {
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

  Future<void> _populatePriceData() async {
    final now = TZDateTime.now(_location);
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
