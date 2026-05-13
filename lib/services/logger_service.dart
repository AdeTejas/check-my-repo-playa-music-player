import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class LoggerService {
  static final LoggerService instance = LoggerService._();

  late final Logger _logger;

  LoggerService._() {
    _logger = Logger('Playa');
  }

  void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final message =
          '[${record.level.name}] ${record.loggerName}: ${record.message}';
      if (record.error != null) {
        debugPrint('$message\n${record.error}');
      } else {
        debugPrint(message);
      }
      if (record.stackTrace != null) {
        debugPrint(record.stackTrace.toString());
      }
    });
  }

  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(Level.INFO, message, error, stackTrace);
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(Level.WARNING, message, error, stackTrace);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(Level.SEVERE, message, error, stackTrace);
  }
}
