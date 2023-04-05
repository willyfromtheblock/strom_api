import '../bin/pvpc_server.dart' as app;
import 'package:test/test.dart';

void main() {
  group(
    'app bin',
    () {
      test('app should fail to start without proper env', () {
        expect(() async => await app.main(), throwsException);
      });
    },
  );
}
