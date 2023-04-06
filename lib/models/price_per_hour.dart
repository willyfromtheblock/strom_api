import 'package:strom_api/zones/price_zone.dart';

enum PriceRating { peak, offPeak }

class PricePerHour {
  DateTime time;
  double priceInEUR;
  PriceRating rating = PriceRating.peak;
  double priceRelativeToDayAverageInPercent = 0.0;
  PriceZones zone;

  @override
  String toString() {
    return "$time - ${zone.name} - $priceInEUR€ - $rating - $priceRelativeToDayAverageInPercent%";
  }

  Map toMap() {
    return {
      'time': time.toString(),
      'zone': zone.name,
      'price': priceInEUR,
      'price_rating_percent': priceRelativeToDayAverageInPercent,
      'price_rating': rating == PriceRating.peak ? 'peak' : 'off_peak',
    };
  }

  PricePerHour({
    required this.time,
    required this.priceInEUR,
    required this.zone,
  });
}
