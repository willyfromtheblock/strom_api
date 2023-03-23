import 'dart:async';

import 'package:alfred/alfred.dart';
import 'package:timezone/timezone.dart';

import 'price_watcher.dart';
import 'tools/logger.dart';

class AlfredServer {
  final _logger = LoggerWrapper().logger;
  final app = Alfred(logLevel: LogType.warn);
  Location location = getLocation('Europe/Madrid');

  Future<void> serve() async {
    app.get('/price-now', (req, res) async {
      final prices = PriceWatcher().prices;
      final timeNow = TZDateTime.now(location);
      await res.json(
        prices
            .firstWhere(
              (element) =>
                  element.time.hour == timeNow.hour &&
                  element.time.day == timeNow.day,
            )
            .toMap(),
      );
    });

    app.get('/price-average-today', (req, res) async {
      final priceAverages = PriceWatcher().priceAverages;
      final timeNow = TZDateTime.now(location);
      await res.json(
        priceAverages
            .firstWhere(
              (element) =>
                  element.time.hour == timeNow.hour &&
                  element.time.day == timeNow.day,
            )
            .toMap(),
      );
    });

    final server = await app.listen();
    _logger.i('alfred: Listening on ${server.port}');
  }

  //TODO endpoint to get price at time x
}
