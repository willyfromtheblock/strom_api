import 'dart:async';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:collection/collection.dart';
import 'package:pvpc_server/tools/price_zone.dart';
import 'package:timezone/timezone.dart';

import 'price_watcher.dart';
import 'tools/logger.dart';

class AlfredServer {
  final _logger = LoggerWrapper().logger;

  final _httpServer = Alfred(
    logLevel: LogType.values.firstWhere(
      (element) => Platform.environment['HTTP_LOG_LEVEL']! == element.name,
    ),
  );

  final Location _locationMadrid = getLocation('Europe/Madrid');
  final Location _locationCanaries = getLocation('Atlantic/Canary');
  final AlfredException _notInSetException = AlfredException(
    400,
    {
      "message":
          "This timestamp is not included in the current table. pvpc_server only serves the present day and the next day. Next day's data is available after 20:30 (Madrid time) of the preceeding day."
    },
  );

  PriceZone _convertStringToZone(String zone) {
    final zoneEnum =
        PriceZone.values.firstWhereOrNull((element) => element.name == zone);

    if (zoneEnum == null) {
      throw AlfredException(
        400,
        {
          "message":
              "Invalid zone. Valid values are peninsular, canarias, baleares, ceuta and melilla"
        },
      );
    }
    return zoneEnum;
  }

  TZDateTime _getTimeForZone(PriceZone zone, DateTime timestamp) {
    if (zone.name == 'canarias') {
      return TZDateTime.from(timestamp, _locationCanaries);
    } else {
      return TZDateTime.from(timestamp, _locationMadrid);
    }
  }

  DateTime _parseDateTime(int timestampInSecondsSinceEpoch) {
    if (timestampInSecondsSinceEpoch == 0) {
      return DateTime.now();
    }
    return DateTime.fromMillisecondsSinceEpoch(
      timestampInSecondsSinceEpoch * 1000,
    );
  }

  Future<void> serve() async {
    /// price endpoint
    ///
    /// Returns JSON with price data for the hour that matches the timestamp in the given zone.
    /// Returned "time" object is  l o c a l time in the given zone.
    ///
    /// Parameter 1:
    /// int - timestamp: in s e c o n d s unix time U T C
    /// if timestamp is 0, current local time for the zone will be used
    ///
    /// Parameter 2:
    /// String - zone: either peninsular, canarias, baleares, ceuta or melilla

    _httpServer.get(
      '/price/:timestamp:int/:zone:[a-z]+',
      (req, res) async {
        final zone = _convertStringToZone(req.params['zone']);
        final timestamp = _parseDateTime(req.params['timestamp']);
        final timeNow = _getTimeForZone(zone, timestamp);

        final prices = PriceWatcher().prices;
        await res.json(
          prices
              .firstWhere(
                (element) =>
                    element.time.hour == timeNow.hour &&
                    element.time.day == timeNow.day &&
                    element.zone == zone,
                orElse: () => throw _notInSetException,
              )
              .toMap(),
        );
      },
    );

    /// price-average endpoint
    ///
    /// Returns JSON with price average for the day that matches the timestamp in the given zone.
    /// Returned "time" object is l o c a l time in the given zone.
    ///
    /// Parameter 1:
    /// int - timestamp: in s e c o n d s unix time U T C
    /// if timestamp is 0, current local time for the zone will be used
    /// Parameter 2:
    /// String - zone: either peninsular, canarias, baleares, ceuta or melilla
    ///

    _httpServer.get(
      '/price-average/:timestamp:int/:zone:[a-z]+',
      (req, res) async {
        final zone = _convertStringToZone(req.params['zone']);
        final timestamp = _parseDateTime(req.params['timestamp']);
        final timeNow = _getTimeForZone(zone, timestamp);

        final priceAverages = PriceWatcher().priceAverages;
        await res.json(
          priceAverages
              .firstWhere(
                (element) =>
                    element.time.day == timeNow.day && element.zone == zone,
                orElse: () => throw _notInSetException,
              )
              .toMap(),
        );
      },
    );

    final server = await _httpServer.listen(
      int.parse(Platform.environment['HTTP_PORT']!),
    );
    _logger.i('http_server: Listening on ${server.port}');
  }
}
