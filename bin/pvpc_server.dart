import 'package:pvpc_server/http_server.dart';
import 'package:pvpc_server/price_watcher.dart';
import 'package:pvpc_server/tools/http_wrapper.dart';
import 'package:pvpc_server/tools/logger.dart';

Future<void> main(List<String> arguments) async {
  LoggerWrapper().init();
  HttpWrapper().init();
  await PriceWatcher().init();
  await AlfredServer().serve();
}
