import 'package:logger/logger.dart';
import 'package:mem/repositories/log_repository.dart' as repository;

class LoggerWrapper {
  Logger _logger;

  LoggerWrapper._(this._logger);

  void log(repository.Level level, dynamic message) =>
      _logger.log(level._convert(), message);

  static LoggerWrapper? _instance;

  factory LoggerWrapper() {
    var tmp = _instance;
    if (tmp == null) {
      tmp = LoggerWrapper._(
        Logger(),
      );
      _instance = tmp;
    }
    return tmp;
  }
}

extension on repository.Level {
  Level _convert() {
    switch (this) {
      case repository.Level.verbose:
        return Level.verbose;
      case repository.Level.trace:
        return Level.info;
      case repository.Level.warning:
        return Level.warning;
      case repository.Level.error:
        return Level.error;
      case repository.Level.debug:
        return Level.debug;
    }
  }
}
