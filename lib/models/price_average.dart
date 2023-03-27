class PriceAverage {
  DateTime time;
  double averagePriceInEUR;

  @override
  String toString() {
    return "$time - $averagePriceInEUR ";
  }

  Map toMap() {
    return {
      'time': time.toUtc().toString(),
      'average_price': averagePriceInEUR,
    };
  }

  PriceAverage({
    required this.time,
    required this.averagePriceInEUR,
  });
}
