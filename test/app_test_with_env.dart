import 'dart:io';

import 'package:dio/dio.dart';
import 'package:strom_api/price_watcher.dart';
import 'package:strom_api/zones/price_zone.dart';

import '../bin/strom_api.dart' as app;
import 'package:test/test.dart';

void main() {
  late Dio dio;
  setUp(() {
    String restURL = 'http://localhost:3001';

    dio = Dio(
      BaseOptions(
        baseUrl: restURL,
        headers: {
          "X-RapidAPI-Proxy-Secret": Platform.environment['RAPID_API_SECRET'],
        },
      ),
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
        expect(PriceWatcher().priceAverages.isNotEmpty, true);
      });
      test('dump price data', () async {
        for (var element in PriceWatcher().prices) {
          print(element.toString());
        }
        for (var element in PriceWatcher().priceAverages) {
          print(element.toString());
        }
      });
    },
  );

  group('RestServer', () {
    group(
      'price-now',
      () {
        test('get all available zones', () async {
          for (var zone in PriceZones.values) {
            await dio.get('/price/0/${zone.name}');
          }
        });

        test('get non existing zone', () async {
          expect(
            () async => await dio.get(
              '/price/0/berlin',
            ),
            throwsA(
              isA<DioException>(),
            ),
          );
        });

        test('get price in one hour in peninsular', () async {
          final time = DateTime.now().add(Duration(hours: 1));
          final secondsSinceEpoch = time.millisecondsSinceEpoch ~/ 1000;
          await dio.get(
            '/price/$secondsSinceEpoch/peninsular',
          );
        });

        test('get price in two days in peninsular', () async {
          final time = DateTime.now().add(Duration(days: 2));
          final secondsSinceEpoch = time.millisecondsSinceEpoch ~/ 1000;

          expect(
            () async => await dio.get(
              '/price/$secondsSinceEpoch/peninsular',
            ),
            throwsA(
              isA<DioException>(),
            ),
          );
        });
      },
    );
    group(
      'price-daily',
      () {
        test('get all available zones', () async {
          for (var zone in PriceZones.values) {
            await dio.get('/price-daily/0/${zone.name}');
          }
        });

        test('get non existing zone', () async {
          expect(
            () async => await dio.get(
              '/price-daily/0/berlin',
            ),
            throwsA(
              isA<DioException>(),
            ),
          );
        });

        test('get price in one hour in peninsular', () async {
          final time = DateTime.now().add(Duration(hours: 1));
          final secondsSinceEpoch = time.millisecondsSinceEpoch ~/ 1000;
          await dio.get(
            '/price-daily/$secondsSinceEpoch/peninsular',
          );
        });

        test('get price in two days in peninsular', () async {
          final time = DateTime.now().add(Duration(days: 2));
          final secondsSinceEpoch = time.millisecondsSinceEpoch ~/ 1000;

          expect(
            () async => await dio.get(
              '/price-daily/$secondsSinceEpoch/peninsular',
            ),
            throwsA(
              isA<DioException>(),
            ),
          );
        });
      },
    );
    group(
      'price-average',
      () {
        test('get all available zones', () async {
          for (var zone in PriceZones.values) {
            await dio.get('/price-average/0/${zone.name}');
          }
        });

        test('get non existing zone', () async {
          expect(
            () async => await dio.get(
              '/price-average/0/berlin',
            ),
            throwsA(
              isA<DioException>(),
            ),
          );
        });

        test('get price-average in one hour in peninsular', () async {
          final time = DateTime.now().add(Duration(hours: 1));
          final secondsSinceEpoch = time.millisecondsSinceEpoch ~/ 1000;
          await dio.get(
            '/price-average/$secondsSinceEpoch/peninsular',
          );
        });

        test('get price-average in two days in peninsular', () async {
          final time = DateTime.now().add(Duration(days: 2));
          final secondsSinceEpoch = time.millisecondsSinceEpoch ~/ 1000;

          expect(
            () async => await dio.get(
              '/price-average/$secondsSinceEpoch/peninsular',
            ),
            throwsA(
              isA<DioException>(),
            ),
          );
        });
      },
    );
  });
}
