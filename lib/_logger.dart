// coverage:ignore-file
import 'package:logger/logger.dart' as External;

final filePath = 'mem/_logger.dart';

@deprecated
T _dev<T>(T message) {
  Logger()._log(
    External.Level.debug,
    message,
    stackTrace: StackTrace.current,
  );
  return message;
}

@deprecated
T _d<T>(dynamic arguments, T Function() function) => Logger()._functionLog(
      External.Level.debug,
      function,
      arguments,
    );

T _v<T>(
  dynamic arguments,
  T Function() function, {
  @deprecated bool debug = false,
}) =>
    debug
        // ignore: deprecated_member_use_from_same_package
        ? _d(arguments, function)
        : Logger()._functionLog(
            External.Level.verbose,
            function,
            arguments,
          );

T _i<T>(
  dynamic arguments,
  T Function() function, {
  @deprecated bool debug = false,
}) =>
    debug
        // ignore: deprecated_member_use_from_same_package
        ? _d(arguments, function)
        : Logger()._functionLog(
            External.Level.info,
            function,
            arguments,
          );

class Logger {
  final External.Logger _logger;

  T error<T>(T message, Object error, StackTrace? stackTrace) =>
      this._log(External.Level.error, message,
          error: error, stackTrace: stackTrace);

  T _functionLog<T>(
    External.Level level,
    T Function() function,
    dynamic arguments, {
    StackTrace? stackTrace,
  }) {
    final _stackTrace = stackTrace ?? StackTrace.current;
    this._log(level, '<= $arguments', stackTrace: _stackTrace);

    try {
      final result = function();

      if (result is Future) {
        result.then((value) {
          this._log(level, '=> Future $value', stackTrace: _stackTrace);
        });
      } else {
        this._log(level, '=> $result', stackTrace: _stackTrace);
      }

      return result;
    } catch (e) {
      this._logger.log(External.Level.error, 'Exception caught.', e);
      throw e;
    }
  }

  T _log<T>(
    External.Level level,
    T message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.log(level, message, error, stackTrace);

    return message;
  }

  static Logger? _instance;

  Logger._(bool onTest)
      : _logger = External.Logger(
          filter: LogFilter(onTest, _checkUnderDevelopment),
          printer: LogPrinter(_checkUnderDevelopment),
          level: External.Level.info,
        );

  factory Logger({bool onTest = false}) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = Logger._(onTest);
      _instance = tmp;
    }
    return tmp;
  }

//   // FIXME きもい。ファイルパスから見るとかできんかな
//   // TODO この仕様だと非同期の結果をキャッチできない
  static bool _checkUnderDevelopment(StackTrace? stackTrace) {
    final _stackTrace = stackTrace?.toString();
    if (_stackTrace == null) {
      return false;
    } else {
      return _stackTrace.contains('d (package:$filePath') ||
          _stackTrace.contains('dev (package:$filePath');
    }
  }
}

class LogPrinter extends External.PrettyPrinter {
  final bool Function(StackTrace?) _checkUnderDevelopment;

  LogPrinter(this._checkUnderDevelopment)
      : super(methodCount: 1, errorMethodCount: 1);

  @override
  String? formatStackTrace(StackTrace? stackTrace, int methodCount) {
    return super.formatStackTrace(
      StackTrace.fromString((stackTrace.toString().split('\n')
            ..removeWhere((element) => _checkUnderLogger(element)))
          .join('\n')),
      this._checkUnderDevelopment(stackTrace) ? 5 : methodCount,
    );
  }

  // FIXME きもい。ファイルパスから見るとかできんかな
  bool _checkUnderLogger(String stackTrace) =>
      stackTrace.contains('package:$filePath');
}

class LogFilter extends External.DevelopmentFilter {
  final bool onTest;
  final bool Function(StackTrace?) _checkUnderDevelopment;

  LogFilter(this.onTest, this._checkUnderDevelopment);

  @override
  bool shouldLog(External.LogEvent event) {
    if (this.onTest) {
      return true;
    } else if (_checkUnderDevelopment(event.stackTrace)) {
      return true;
    } else {
      return super.shouldLog(event);
    }
  }
}
