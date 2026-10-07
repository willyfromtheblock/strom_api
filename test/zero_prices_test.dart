import 'dart:convert';
import 'dart:io';

import 'package:strom_api/price_watcher.dart';
import 'package:strom_api/tools/http_wrapper.dart';
import 'package:strom_api/tools/logger.dart';
import 'package:test/test.dart';

void main() {
  test('all-zero PVPC data is rejected and not cached', () async {
    // fake REE API that serves 24 zero prices for any requested day
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      final day = req.uri.queryParameters['start_date']!.split('T')[0];
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({
        'included': [
          {
            'id': '1001',
            'attributes': {
              'values': [
                for (var h = 0; h < 24; h++)
                  {
                    'value': 0,
                    'datetime':
                        '${day}T${h.toString().padLeft(2, '0')}:00:00.000+02:00',
                  },
              ],
            },
          },
        ],
      }));
      req.response.close();
    });

    LoggerWrapper().init();
    HttpWrapper().init(baseUrl: 'http://localhost:${server.port}', retries: 0);

    await expectLater(PriceWatcher().init(), throwsA(isA<Exception>()));
    expect(PriceWatcher().prices, isEmpty);
    expect(PriceWatcher().priceAverages, isEmpty);

    await server.close(force: true);
  });
}
