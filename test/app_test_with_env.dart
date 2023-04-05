import 'package:pvpc_server/price_watcher.dart';
import 'package:pvpc_server/tools/http_wrapper.dart';
import 'package:pvpc_server/tools/logger.dart';

import '../bin/pvpc_server.dart' as app;
import 'package:test/test.dart';

void main() {
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
      test('init PriceWatcher', () async {
        await PriceWatcher().init();
      });
    },
  );

  group(
    'RestServer',
    () {},
  );
}
