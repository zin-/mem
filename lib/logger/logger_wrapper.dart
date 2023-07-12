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

  LoggerWrapper([bool enableSimpleMode = false])
      : _logger = Logger(
          filter: DevelopmentFilter(),
          printer: enableSimpleMode ? _SimplePrinter() : _LogPrinter(),
        );
}

const lineBreak = '\n';
const loggerPackagePath = 'package:mem/logger';

class _LogPrinter extends PrettyPrinter {
  _LogPrinter()
      : super(
          methodCount: 1,
          errorMethodCount: 10,
          printTime: true,
        );

  @override
  String? formatStackTrace(StackTrace? stackTrace, int methodCount) {
    return super.formatStackTrace(
      StackTrace.fromString(stackTrace
          .toString()
          .split(lineBreak)
          .where((line) => !line.contains(loggerPackagePath))
          .join(lineBreak)),
      methodCount,
    );
  }
}

class _SimplePrinter extends SimplePrinter {
  _SimplePrinter() : super(printTime: true);

  @override
  List<String> log(LogEvent event) {
    return super.log(LogEvent(
      event.level,
      '${RegExp(r'#[0-9]+\s+(.+) \((\S+)\)').matchAsPrefix((event.stackTrace ?? StackTrace.current).toString().split(lineBreak).where(
            (line) =>
                !line.contains(loggerPackagePath) &&
                !line.contains('package:logger'),
          ).first)?.group(1) ?? '???'}'
      ' ${event.message}',
      event.error,
      event.stackTrace,
    ));
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
