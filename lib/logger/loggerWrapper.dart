import 'package:logger/logger.dart';

import 'i/type.dart' as i;

const _filePath = 'mem/wrappers/loggerWrapper.dart';

class LoggerWrapper {
  Logger _logger;

  LoggerWrapper._(this._logger);

  void log(
    i.Level level,
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) =>
      _logger.log(level._convert(), message, error, stackTrace);

  static LoggerWrapper? _instance;

  factory LoggerWrapper(
    i.Level level,
    bool Function(String line, String filePath)? shouldOutputStackTraceLine,
  ) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = LoggerWrapper._(
        Logger(
          filter: _LogFilter(),
          printer: _LogPrinter(shouldOutputStackTraceLine),
          level: level._convert(),
        ),
      );
      _instance = tmp;
    }
    return tmp;
  }

  static reset() => _instance = null;
}

class _LogFilter extends DevelopmentFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (event.level == Level.debug) {
      return true;
    }

    return super.shouldLog(event);
  }
}

class _LogPrinter extends PrettyPrinter {
  final bool Function(String line, String filePath)?
      _shouldOutputStackTraceLine;

  _LogPrinter(this._shouldOutputStackTraceLine)
      : super(methodCount: 1, errorMethodCount: 1);

  @override
  String? formatStackTrace(StackTrace? stackTrace, int methodCount) {
    const n = '\n';
    final stackTraceLines = stackTrace.toString().split(n);
    final shouldOutputStackTraceLines = stackTraceLines.where(
      (line) => _shouldOutputStackTraceLine?.call(line, _filePath) ?? true,
    );
    return super.formatStackTrace(
      StackTrace.fromString(shouldOutputStackTraceLines.join(n)),
      methodCount,
    );
  }
}

extension on i.Level {
  Level _convert() {
    switch (this) {
      case i.Level.verbose:
        return Level.verbose;
      case i.Level.trace:
        return Level.info;
      case i.Level.warning:
        return Level.warning;
      case i.Level.error:
        return Level.error;
      case i.Level.debug:
        return Level.debug;
    }
  }
}
