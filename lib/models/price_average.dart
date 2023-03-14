class PriceAverage {
  DateTime time;
  double averagePriceInEUR;

  Map toMap() {
    return {
      'time': time.toString(),
      'average_price': averagePriceInEUR,
    };
  }

  PriceAverage({
    required this.time,
    required this.averagePriceInEUR,
  });
}
