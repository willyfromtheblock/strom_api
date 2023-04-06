/// Find the implementation of the strom_api endpoints.
///
/// {@category REST}
library rest_server;

import 'dart:async';
import 'dart:io';

import 'package:alfred/alfred.dart';
import 'package:collection/collection.dart';
import 'package:strom_api/tools/price_zone.dart';
import 'package:timezone/timezone.dart';

import 'price_watcher.dart';
import 'tools/logger.dart';

class RESTServer {
  final _logger = LoggerWrapper().logger;
  final bool protectedMode;

  RESTServer({required this.protectedMode});

  final _httpServer = Alfred(
    logLevel: LogType.values.firstWhere(
      (element) => Platform.environment['HTTP_LOG_LEVEL']! == element.name,
    ),
  );

  final Location _locationMadrid = getLocation('Europe/Madrid');
  final Location _locationCanaries = getLocation('Atlantic/Canary');
  final AlfredException notInSetException = AlfredException(
    400,
    {
      "message":
          "This timestamp is not included in the current table. strom_api does not serve this time frame."
    },
  );
  final AlfredException notInZoneException = AlfredException(
    400,
    {"message": "Invalid zone."},
  );

  Future<void> serve() async {
    //API header middleware
    //Enable only if API protected mode is true in env variables
    if (protectedMode == true) {
      _httpServer.all(
        '*',
        (req, res) {
          if (req.headers.value('X-RapidAPI-Proxy-Secret') !=
              Platform.environment['RAPID_API_SECRET']!) {
            throw AlfredException(
              401,
              {'error': 'You are not authorized to perform this operation'},
            );
          }
        },
      );
    }

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
                orElse: () => throw notInSetException,
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
                orElse: () => throw notInSetException,
              )
              .toMap(),
        );
      },
    );

    //TODO endpoint for range

    final server = await _httpServer.listen(
      int.parse(Platform.environment['HTTP_PORT']!),
    );
    _logger.i('http_server: Listening on ${server.port}');
  }

  PriceZone _convertStringToZone(String zone) {
    final zoneEnum =
        PriceZone.values.firstWhereOrNull((element) => element.name == zone);

    if (zoneEnum == null) {
      throw notInZoneException;
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
}
