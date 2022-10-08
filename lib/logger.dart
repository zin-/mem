// FIXME プラットフォームとの連携なので、Repositoryにする
// coverage:ignore-file
import 'package:logger/logger.dart' as ex;

const filePath = 'mem/logger';

T v<T>(
  dynamic arguments,
  T Function() function, {
  @Deprecated('Allow under develop only') bool debug = false,
}) =>
    debug
        // ignore: deprecated_member_use_from_same_package
        ? d(arguments, function)
        : Logger().functionLog(Level.verbose, function, arguments);

T t<T>(
  dynamic arguments,
  T Function() function, {
  @Deprecated('Allow under develop only') bool debug = false,
}) =>
    debug
        // ignore: deprecated_member_use_from_same_package
        ? d(arguments, function)
        : Logger().functionLog(Level.trace, function, arguments);

@Deprecated('Allow under develop only')
T d<T>(
  dynamic arguments,
  T Function() function,
) =>
    Logger().functionLog(Level.debug, function, arguments);

T verbose<T>(T object) => Logger().log(Level.verbose, object);

T trace<T>(T object) => Logger().log(Level.trace, object);

T warn<T>(T object) => Logger().log(Level.warning, object);

@Deprecated('Allow under develop only')
T dev<T>(T object) => Logger().log(Level.debug, object);

enum Level {
  verbose,
  trace,
  warning,
  error,
  debug,
}

extension on Level {
  ex.Level _convertIntoEx() {
    switch (this) {
      case Level.verbose:
        return ex.Level.verbose;
      case Level.trace:
        return ex.Level.info;
      case Level.warning:
        return ex.Level.warning;
      case Level.error:
        return ex.Level.error;
      case Level.debug:
        return ex.Level.debug;
    }
  }
}

class Logger {
  final Level _level;
  final ex.Logger _logger;

  T log<T>(Level level, T object, {String? message, StackTrace? stackTrace}) {
    if (level.index >= _level.index) {
      if (object is Future) {
        _futureLog(level, object, message, stackTrace ?? StackTrace.current);
      } else if (object is Function()) {
        warn('Use functionLog. I try auto cast.');
        functionLog(level, object, {});
      } else if (object is Error || object is Exception) {
        _messageLog(
          level,
          message == null ? object : _buildMessageWithValue(message, object),
          error: object,
          stackTrace: stackTrace,
        );
      } else {
        _messageLog(
          level,
          message == null ? object : _buildMessageWithValue(message, object),
          stackTrace: stackTrace,
        );
      }
    }

    return object;
  }

  T functionLog<T>(
    Level level,
    T Function() function,
    dynamic arguments, {
    String? message,
  }) {
    if (level.index >= _level.index) {
      final stackTrace = StackTrace.current;
      log(level, arguments, message: 'start', stackTrace: stackTrace);
      final result = function();
      log(level, result, message: 'end', stackTrace: stackTrace);
      return result;
    }
    return function();
  }

  void _futureLog(
    Level level,
    Future future,
    dynamic message,
    StackTrace stackTrace,
  ) {
    future.then(
      (value) {
        log(level, value,
            message: 'Future => $message', stackTrace: stackTrace);
      },
      onError: (e) {
        log(
          Level.error,
          e,
          message: 'Future => Error => $message',
          stackTrace: stackTrace,
        );
      },
    );
  }

  void _messageLog(
    Level level,
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
  }) =>
      _logger.log(
        level._convertIntoEx(),
        message.toString().split('\n').first,
        error,
        stackTrace,
      );

  String _buildMessageWithValue(String message, dynamic object) =>
      object == null ? message : '$message :: $object';

  static Logger? _instance;

  Logger._(this._level)
      : _logger = ex.Logger(
          filter: _LogFilter(),
          printer: _LogPrinter(),
          level: _level._convertIntoEx(),
        );

  factory Logger({Level level = Level.trace}) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = Logger._(level);
      _instance = tmp;
    }
    return tmp;
  }
}

class _LogFilter extends ex.LogFilter {
  @override
  bool shouldLog(ex.LogEvent event) {
    var shouldLog = false;
    if (event.level == ex.Level.debug) {
      shouldLog = true;
    } else {
      if (event.level.index >= level!.index) {
        shouldLog = true;
      }
    }

    if (!shouldLog) {
      var lines = event.stackTrace.toString().split('\n');

      for (var line in lines) {
        shouldLog = _checkUnderDevelopOnParents(line);
        if (shouldLog) {
          break;
        }
      }
    }

    return shouldLog;
  }

  bool _checkUnderDevelopOnParents(String line) {
    var match = _deviceStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    return match.group(1) == 'd' &&
        match.group(2)!.startsWith('package:$filePath');
  }
}

class _LogPrinter extends ex.PrettyPrinter {
  _LogPrinter() : super(methodCount: 1, errorMethodCount: 1);

  @override
  String? formatStackTrace(StackTrace? stackTrace, int methodCount) {
    var lines = stackTrace.toString().split('\n');
    // FIXME naming
    var discarded = <String>[];
    for (var line in lines) {
      if (line.isEmpty ||
          _discardDeviceStacktraceLine(line) ||
          _discardWebStacktraceLine(line) ||
          _discardBrowserStacktraceLine(line)) {
        continue;
      }
      discarded.add(line);
    }

    // TODO override methodCount
    if (discarded.isEmpty) {
      return null;
    } else {
      return super.formatStackTrace(
        StackTrace.fromString(discarded.join('\n')),
        methodCount,
      );
    }
  }

  bool _discardDeviceStacktraceLine(String line) {
    var match = _deviceStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    return match.group(2)!.startsWith('package:$filePath');
  }

  bool _discardWebStacktraceLine(String line) {
    var match = _webStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return line.contains('dart-sdk') ||
          line.contains('flutter_web_sdk') ||
          line.contains('web_entrypoint');
    }
    return match.group(1)!.startsWith('packages/$filePath');
  }

  bool _discardBrowserStacktraceLine(String line) {
    var match = _browserStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    return match.group(1)!.startsWith('package:$filePath');
  }
}

// Copied from package:logger/logger/printers/pretty_printer.dart
final _deviceStackTraceRegex = RegExp(r'#[0-9]+\s+(.+) \((\S+)\)');
final _webStackTraceRegex = RegExp(r'^((packages|dart-sdk)/\S+/\S+)');
final _browserStackTraceRegex = RegExp(r'^(?:package:)?(dart:\S+|\S+)');
