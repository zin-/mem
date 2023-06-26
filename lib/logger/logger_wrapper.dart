import 'package:logger/logger.dart';

import 'log_entity.dart' as log_entity;

class LoggerWrapper {
  final Logger _logger;

  void log(
    log_entity.Level level,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) =>
      _logger.log(
        level._transform(),
        message,
        error,
        stackTrace,
      );

  LoggerWrapper()
      : _logger = Logger(
          filter: DevelopmentFilter(),
          printer: _LogPrinter(),
        );
}

class _LogPrinter extends PrettyPrinter {
  _LogPrinter()
      : super(
          methodCount: 1,
          errorMethodCount: 1,
          printTime: true,
        );

  @override
  String? formatStackTrace(StackTrace? stackTrace, int methodCount) {
    const lineBreak = '\n';
    return super.formatStackTrace(
      StackTrace.fromString(stackTrace
          .toString()
          .split(lineBreak)
          .where(
            (line) => !line.contains('package:mem/logger'),
          )
          .join(lineBreak)),
      methodCount,
    );
  }
}

extension on log_entity.Level {
  Level _transform() {
    switch (this) {
      case log_entity.Level.verbose:
        return Level.verbose;
      case log_entity.Level.debug:
        return Level.debug;
      case log_entity.Level.info:
        return Level.info;
      case log_entity.Level.warning:
        return Level.warning;
      case log_entity.Level.error:
        return Level.error;
    }
  }
}
