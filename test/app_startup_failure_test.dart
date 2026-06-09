import 'package:strom_api/price_watcher.dart';
import 'package:strom_api/tools/http_wrapper.dart';
import 'package:strom_api/tools/logger.dart';
import 'package:test/test.dart';

void main() {
  group('PriceWatcher Startup DNS/Connection Failure', () {
    test('should throw Exception and fail init when API is unreachable', () async {
      LoggerWrapper().init();
      // Initialize with a non-existent URL and 0 retries to make the failure immediate
      HttpWrapper().init(
        baseUrl: 'https://non-existent-host-xyz.invalid',
        retries: 0,
      );

      // PriceWatcher().init() should throw an exception on startup
      expect(
        () async => await PriceWatcher().init(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
