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
  AlfredException notInSetException = AlfredException(
    400,
    {
      "message":
          "This timestamp is not included in the current table. pvpc_server only serves the present day and the next day. Next day's data is available after 20:30 (Madrid time) of the preceeding day."
    },
  );

  TZDateTime getTimeForLocation(String location, DateTime timestamp) {
    if (location == 'canaries') {
      return TZDateTime.from(timestamp, locationCanaries);
    } else if (location == 'peninsula') {
      return TZDateTime.from(timestamp, locationMadrid);
    } else {
      throw AlfredException(
        400,
        {
          "message":
              "Invalid timezone. Valid values are 'canaries' or 'peninsula'"
        },
      );
    }
  }

  DateTime parseDateTime(int timestampInSecondsSinceEpoch) {
    return DateTime.fromMillisecondsSinceEpoch(
      timestampInSecondsSinceEpoch * 1000,
    );
  }

  Future<void> serve() async {
    /* 
    price endpoint
    
    Parameter 1: int - timestamp in s e c o n d s unix time U T C
    Parameter 2: String - timezone, either 'canaries' or 'peninsula'

    Returns JSON with price data for the hour that matches the timestamp in the given timezone.  
    Returned "time" object is U T C time in the given timezone.
    */
    app.get(
      '/price/:timestamp:int/:timezone:[a-z]+',
      (req, res) async {
        final timezone = req.params['timezone'];
        final timestamp = parseDateTime(req.params['timestamp']);
        final timeNow = getTimeForLocation(timezone, timestamp);

        final prices = PriceWatcher().prices;
        await res.json(
          prices
              .firstWhere(
                (element) =>
                    element.time.hour == timeNow.hour &&
                    element.time.day == timeNow.day,
                orElse: () => throw notInSetException,
              )
              .toMap(),
        );
      },
    );

    /* 
    price-average endpoint
    
    Parameter 1: int - timestamp in unix time UTC! 
    Parameter 2: String - timezone, either 'canaries' or 'peninsula'

    Returns JSON with price average for the day that matches the timestamp in the given timezone.  
    Returned "time" object is l o c a l time in the given timezone.
    */
    app.get(
      '/price-average/:timestamp:int/:timezone:[a-z]+',
      (req, res) async {
        final timezone = req.params['timezone'];
        final timestamp = parseDateTime(req.params['timestamp']);
        final timeNow = getTimeForLocation(timezone, timestamp);

        final priceAverages = PriceWatcher().priceAverages;
        await res.json(
          priceAverages
              .firstWhere(
                (element) => element.time.day == timeNow.day,
                orElse: () => throw notInSetException,
              )
              .toMap(),
        );
      },
    );

    final server = await app.listen();
    _logger.i('alfred: Listening on ${server.port}');
  }
}
