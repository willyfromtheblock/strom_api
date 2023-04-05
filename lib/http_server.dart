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
  final app = Alfred(logLevel: LogType.warn);
  Location locationMadrid = getLocation('Europe/Madrid');
  Location locationCanaries = getLocation('Atlantic/Canary');
  AlfredException notInSetException = AlfredException(
    400,
    {
      "message":
          "This timestamp is not included in the current table. pvpc_server only serves the present day and the next day. Next day's data is available after 20:30 (Madrid time) of the preceeding day."
    },
  );

  PriceZone convertStringToZone(String zone) {
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

  TZDateTime getTimeForZone(PriceZone zone, DateTime timestamp) {
    if (zone.name == 'canarias') {
      return TZDateTime.from(timestamp, locationCanaries);
    } else {
      return TZDateTime.from(timestamp, locationMadrid);
    }
  }

  DateTime parseDateTime(int timestampInSecondsSinceEpoch) {
    if (timestampInSecondsSinceEpoch == 0) {
      return DateTime.now();
    }
    return DateTime.fromMillisecondsSinceEpoch(
      timestampInSecondsSinceEpoch * 1000,
    );
  }

  Future<void> serve() async {
    /* 
    price endpoint
    
    Parameter 1: 
    int - timestamp: in s e c o n d s unix time U T C
    if timestamp is 0, current local time for the zone will be used
                
    Parameter 2: 
    String - zone: either peninsular, canarias, baleares, ceuta or melilla

    Returns JSON with price data for the hour that matches the timestamp in the given zone.  
    Returned "time" object is  l o c a l time in the given zone.
    */
    app.get(
      '/price/:timestamp:int/:zone:[a-z]+',
      (req, res) async {
        final zone = convertStringToZone(req.params['zone']);
        final timestamp = parseDateTime(req.params['timestamp']);
        final timeNow = getTimeForZone(zone, timestamp);

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

    /* 
    price-average endpoint
    
    Parameter 1: 
    int - timestamp: in s e c o n d s unix time U T C
    if timestamp is 0, current local time for the zone will be used
    Parameter 2: 
    String - zone: either peninsular, canarias, baleares, ceuta or melilla

    Returns JSON with price average for the day that matches the timestamp in the given zone.  
    Returned "time" object is l o c a l time in the given zone.
    */
    app.get(
      '/price-average/:timestamp:int/:zone:[a-z]+',
      (req, res) async {
        final zone = convertStringToZone(req.params['zone']);
        final timestamp = parseDateTime(req.params['timestamp']);
        final timeNow = getTimeForZone(zone, timestamp);

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

    final server = await app.listen(
      int.parse(Platform.environment['HTTP_PORT']!),
    );
    _logger.i('http_server: Listening on ${server.port}');
  }
}
