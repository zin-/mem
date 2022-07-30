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
        : Logger()._functionLog(Level.verbose, function, arguments);

T t<T>(
  dynamic arguments,
  T Function() function, {
  @Deprecated('Allow under develop only') bool debug = false,
}) =>
    debug
        // ignore: deprecated_member_use_from_same_package
        ? d(arguments, function)
        : Logger()._functionLog(Level.trace, function, arguments);

@Deprecated('Allow under develop only')
T d<T>(
  dynamic arguments,
  T Function()? function,
) =>
    Logger().log(Level.debug, arguments, function);

T warning<T>(T arguments) => Logger().log(Level.warning, arguments, null);

T dev<T>(T arguments) => Logger().log(Level.debug, arguments, null);

enum Level {
  verbose,
  trace,
  warning,
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
      case Level.debug:
        return ex.Level.debug;
    }
  }
}

class Logger {
  final ex.Logger _logger;

  log<T>(Level level, dynamic object, T Function()? function) {
    final stackTrace = StackTrace.current;
    if (function == null) {
      if (object is Future) {
        _futureLog(level, 'base', object, stackTrace);
      } else if (object is Exception) {
        if (level == Level.warning) {
          _messageLog(level, _buildMessageWithValue('Warning', object));
        } else {
          _exceptionLog(level, 'Error', object);
        }
      } else {
        _messageLog(level, object.toString(), stackTrace: stackTrace);
      }
    } else {
      _functionLog(level, function, object);
    }
  }

  T _functionLog<T>(
    Level level,
    T Function() function,
    dynamic arguments,
  ) {
    final stackTrace = StackTrace.current;
    _messageLog(
      level,
      _buildMessageWithValue('start', arguments),
      stackTrace: stackTrace,
    );
    final result = function();
    if (result is Future) {
      _futureLog(level, 'end', result, stackTrace);
    } else {
      _messageLog(
        level,
        _buildMessageWithValue('end', result),
        stackTrace: stackTrace,
      );
    }
    return result;
  }

  Future<T> _futureLog<T>(
      Level level, String base, Future<T> future, StackTrace stackTrace) async {
    final result = await future;
    _messageLog(
      level,
      'future => ${_buildMessageWithValue(base, result)}',
      stackTrace: stackTrace,
    );
    return result;
  }

  void _messageLog(Level level, String message, {StackTrace? stackTrace}) =>
      _logger.log(level._convertIntoEx(), message, null, stackTrace);

  void _exceptionLog(Level level, String message, Exception exception) =>
      _logger.log(level._convertIntoEx(), message, exception);

  String _buildMessageWithValue(String base, dynamic arguments) =>
      arguments == null ||
              ((arguments is Iterable || arguments is Map) && arguments.isEmpty)
          ? base
          : '$base :: $arguments';

  static Logger? _instance;

  Logger._(Level level)
      : _logger = ex.Logger(
          filter: _LogFilter(),
          printer: _LogPrinter(),
          level: level._convertIntoEx(),
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
      return false;
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
final _webStackTraceRegex = RegExp(r'^((packages|dart-sdk)/\S+/)');
final _browserStackTraceRegex = RegExp(r'^(?:package:)?(dart:\S+|\S+)');
