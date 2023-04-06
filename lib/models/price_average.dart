import 'package:strom_api/zones/price_zone.dart';

class PriceAverage {
  DateTime time;
  double averagePriceInEUR;
  PriceZones zone;

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
