import 'package:dio/dio.dart';
import 'package:pvpc_server/price_watcher.dart';
import 'package:pvpc_server/tools/http_wrapper.dart';
import 'package:pvpc_server/tools/logger.dart';

import '../bin/pvpc_server.dart' as app;
import 'package:test/test.dart';

void main() {
  late Dio dio;
  setUp(() {
    String restURL = 'localhost:3001';

    dio = Dio(
      BaseOptions(baseUrl: restURL),
    );
  });

  group(
    'app bin',
    () {
      test('app should start with proper env', () async {
        await app.main();
      });
    },
  );

  group(
    'PriceWatcher',
    () {
      test('check data populated', () async {
        expect(PriceWatcher().prices.isNotEmpty, true);
      });
    },
  );

  group(
    'RestServer',
    () {
      test('get price now for peninsular', () async {
        print(await dio.get('/price/0/peninsular'));
      });
    },
  );
}
