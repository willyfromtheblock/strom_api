import 'dart:io';

import 'package:pvpc_server/http_server.dart';
import 'package:pvpc_server/price_watcher.dart';
import 'package:pvpc_server/tools/http_wrapper.dart';
import 'package:pvpc_server/tools/logger.dart';

Future<void> main(List<String> arguments) async {
  Map<String, String> env = Platform.environment;
  Map<String, String> requiredEnvs = {
    "LOG_LEVEL": "",
    "HTTP_PORT": "",
  };

  requiredEnvs.forEach((key, value) {
    if (!env.containsKey(key)) {
      throw Exception("$key needs to be in environment");
    } else if (env[key]!.isEmpty) {
      throw Exception("$key needs to have a value");
    }
  });

  LoggerWrapper().init();
  HttpWrapper().init();
  await PriceWatcher().init();
  await AlfredServer().serve();
}
