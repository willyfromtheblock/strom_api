import 'package:timezone/timezone.dart';

import '../models/price_per_hour.dart';
import '../tools/http_wrapper.dart';
import '../tools/logger.dart';
import '../tools/price_zone.dart';
import '../tools/round_to_double_precision.dart';

class APIWrapperES {
  final _logger = LoggerWrapper().logger;
  static final Map<String, APIWrapperES> _cache = <String, APIWrapperES>{};

  factory APIWrapperES() {
    return _cache.putIfAbsent('httpWrapper', () => APIWrapperES._internal());
  }
  APIWrapperES._internal();

  Future<List<PricePerHour>> fetchData({
    required String startTime,
    required String endTime,
    required PriceZone zone,
    required Location location,
  }) async {
    return _parseApiResult(
      res: await _getDataFromAPI(
        startTime: startTime,
        endTime: endTime,
        zone: zone.name,
      ),
      zone: zone,
      location: location,
    );
  }

  Future<Map<String, dynamic>> _getDataFromAPI({
    required String startTime,
    required String endTime,
    required String zone,
  }) async {
    try {
      return await HttpWrapper().get(
        requestJson: true,
        path:
            '/datos/mercados/precios-mercados-tiempo-real?start_date=$startTime&end_date=$endTime&time_trunc=hour&geo_limit=$zone',
      );
    } catch (e) {
      _logger.e(
        'getDataFromAPI: Unable to get prices from API. Shutting down...',
      );
      throw Exception(e.toString());
    }
  }

  List<PricePerHour> _parseApiResult({
    required Map<String, dynamic> res,
    required PriceZone zone,
    required Location location,
  }) {
    final List included = res["included"];
    final List<PricePerHour> answer = [];
    bool found1001 = false;

    //find PVPC with group id 1001
    for (var element in included) {
      if (element['id'] == '1001') {
        found1001 = true;
        final Map<String, dynamic> attributes = element['attributes'];
        final List values = attributes['values'];

        for (var value in values) {
          var priceInCents = roundDoubleToPrecision(value['value'] / 1000, 5);
          answer.add(
            PricePerHour(
              time: TZDateTime.parse(location, value['datetime']),
              priceInEUR: priceInCents,
              zone: zone,
            ),
          );
        }
      }
    }
    if (found1001 == false) {
      _logger.e(
        'parseApiResult: PVPC not included in result. Shutting down...',
      );
      throw Exception();
    }
    return answer;
  }
  //TODO tests
}
