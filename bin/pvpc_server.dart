import 'dart:io';

import 'package:pvpc_server/rest_server.dart';
import 'package:pvpc_server/price_watcher.dart';
import 'package:pvpc_server/tools/http_wrapper.dart';
import 'package:pvpc_server/tools/logger.dart';

Future<void> main() async {
  Map<String, String> env = Platform.environment;
  List<String> requiredEnvs = [
    "PRICE_LOG_LEVEL",
    "HTTP_LOG_LEVEL",
    "HTTP_PORT",
    "RATING_MARGIN",
    "PROTECTED_MODE",
  ];

  for (var requiredEnv in requiredEnvs) {
    if (!env.containsKey(requiredEnv)) {
      throw Exception("$requiredEnv needs to be in environment");
    } else if (env[requiredEnv]!.isEmpty) {
      throw Exception("$requiredEnv needs to have a value");
    }
  }
  final margin = int.parse(env['RATING_MARGIN']!);
  if (margin > 99) {
    throw Exception("RATING_MARGIN needs to be less than 99");
  } else if (margin < 0) {
    throw Exception("RATING_MARGIN needs to be a positive number");
  }

  bool protectedMode = env['PROTECTED_MODE'] == 'true';
  if (protectedMode == true && !env.containsKey('RAPID_API_SECRET')) {
    throw Exception("RAPID_API_SECRET needs to be set in PROTECTED_MODE");
  }

  LoggerWrapper().init();
  HttpWrapper().init();
  await PriceWatcher().init();
  await RESTServer(protectedMode: protectedMode).serve();
}
