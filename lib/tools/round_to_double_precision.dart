double roundDoubleToPrecision(double numberToRound, int precision) {
  final number = numberToRound.toStringAsFixed(precision);
  return double.parse(number);
}
