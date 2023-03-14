import 'dart:io';

import 'package:logger/logger.dart';

class LoggerWrapper {
  static final Map<String, LoggerWrapper> _cache = <String, LoggerWrapper>{};
  late Logger logger;

  factory LoggerWrapper() {
    return _cache.putIfAbsent('logger', () => LoggerWrapper._internal());
  }
  LoggerWrapper._internal();

  Level getLogLevel() {
    Map<String, String> env = Platform.environment;
    var levelInEnv = env["LOG_LEVEL"];
    switch (levelInEnv) {
      case "warning":
        return Level.warning;
      case "info":
        return Level.info;
      case "debug":
        return Level.debug;
      case "error":
        return Level.error;
      case "nothing":
        return Level.nothing;
      default:
        return Level.info;
    }
  }

  void init() {
    logger = Logger(
      level: getLogLevel(),
      printer: PrettyPrinter(
        methodCount: 0,
        printTime: true,
      ),
      filter: ProductionFilter(),
    );
  }
}
