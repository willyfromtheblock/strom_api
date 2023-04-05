import 'package:pvpc_server/tools/price_zone.dart';

class PriceAverage {
  DateTime time;
  double averagePriceInEUR;
  PriceZone zone;

  @override
  String toString() {
    return "$time - ${zone.name} - $averagePriceInEUR ";
  }

  Map toMap() {
    return {
      'time': time.toString(),
      'zone': zone.name,
      'average_price': averagePriceInEUR,
    };
  }

  PriceAverage({
    required this.time,
    required this.averagePriceInEUR,
    required this.zone,
  });
}
