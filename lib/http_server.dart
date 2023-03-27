import 'dart:async';

import 'package:alfred/alfred.dart';
import 'package:timezone/timezone.dart';

import 'price_watcher.dart';
import 'tools/logger.dart';

class AlfredServer {
  final _logger = LoggerWrapper().logger;
  final app = Alfred(logLevel: LogType.warn);
  Location locationMadrid = getLocation('Europe/Madrid');
  Location locationCanaries = getLocation('Atlantic/Canary');

  TZDateTime getTimeForLocation(String location) {
    if (location == 'canaries') {
      return TZDateTime.now(locationCanaries);
    } else {
      return TZDateTime.now(locationMadrid);
    }
  }

  Future<void> serve() async {
    //price-now endpoint
    app.get(
      '/price-now/:location:[a-z]+',
      (req, res) async {
        final location = req.params['location'];
        final timeNow = getTimeForLocation(location);

        final prices = PriceWatcher().prices;
        await res.json(
          prices
              .firstWhere(
                (element) =>
                    element.time.hour == timeNow.hour &&
                    element.time.day == timeNow.day,
              )
              .toMap(),
        );
      },
    );

    //price-average-now endpoint
    app.get(
      '/price-average-now/:location:[a-z]+',
      (req, res) async {
        final location = req.params['location'];
        final timeNow = getTimeForLocation(location);

        final priceAverages = PriceWatcher().priceAverages;
        await res.json(
          priceAverages
              .firstWhere(
                (element) => element.time.day == timeNow.day,
              )
              .toMap(),
        );
      },
    );

    final server = await app.listen();
    _logger.i('alfred: Listening on ${server.port}');
  }

  //TODO endpoint to get price at time x
}
