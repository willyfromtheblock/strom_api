// import 'package:pvpc_server/pvpc_server.dart';
import 'package:test/test.dart';

void main() {
  bool populatePriceDataHourCheck(int hour) {
    if (hour >= 20 && hour <= 23) {
      return true;
    }
    return false;
  }

  test('check populatePriceData hour logic', () {
    assert(populatePriceDataHourCheck(19) == false);
    assert(populatePriceDataHourCheck(20) == true);
    assert(populatePriceDataHourCheck(21) == true);
    assert(populatePriceDataHourCheck(22) == true);
    assert(populatePriceDataHourCheck(23) == true);
    assert(populatePriceDataHourCheck(0) == false);
  });
}
