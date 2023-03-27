enum PriceRating { peak, offPeak }

class PricePerHour {
  DateTime time;
  double priceInEUR;
  PriceRating rating = PriceRating.peak;
  double priceRelativeToDayAverageInPercent = 0.0;

  @override
  String toString() {
    return "$time - $priceInEUR€ - $rating - $priceRelativeToDayAverageInPercent%";
  }

  Map toMap() {
    return {
      'time': time.toUtc().toString(),
      'price': priceInEUR,
      'price_rating_percent': priceRelativeToDayAverageInPercent,
      'price_rating': rating == PriceRating.peak ? 'peak' : 'off_peak',
    };
  }

  PricePerHour({
    required this.time,
    required this.priceInEUR,
  });
}
