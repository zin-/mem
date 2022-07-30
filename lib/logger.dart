import 'package:logger/logger.dart' as ex;

const filePath = 'mem/logger';

T t<T>(dynamic arguments, T Function() function) =>
    Logger()._functionLog(Level.trace, function, arguments);

T v<T>(dynamic arguments, T Function() function) =>
    Logger()._functionLog(Level.verbose, function, arguments);

enum Level {
  verbose,
  trace,
}

extension on Level {
  ex.Level _convertIntoEx() {
    switch (this) {
      case Level.verbose:
        return ex.Level.verbose;
      case Level.trace:
        return ex.Level.info;
    }
  }
}

class Logger {
  final ex.Logger _logger;

  T _functionLog<T>(Level level, T Function() function, [dynamic arguments]) {
    _objectLog(
      level,
      _buildMessageWithValues('start', arguments),
    );
    final result = function();
    if (result is Future) {
      _futureLog(level, 'future => end', result, StackTrace.current);
    } else {
      _objectLog(
        level,
        _buildMessageWithValues('end', result),
      );
    }
    return result;
  }

  _futureLog(
      Level level, String base, Future future, StackTrace stackTrace) async {
    final result = await future;
    _objectLog(
      level,
      _buildMessageWithValues(base, result),
      stackTrace: stackTrace,
    );
  }

  void _objectLog(Level level, Object object, {StackTrace? stackTrace}) =>
      _logger.log(level._convertIntoEx(), object, null, stackTrace);

  String _buildMessageWithValues(String base, dynamic arguments) =>
      arguments == null ||
              ((arguments is Iterable || arguments is Map) && arguments.isEmpty)
          ? base
          : '$base :: $arguments';

  static Logger? _instance;

  Logger._() : _logger = ex.Logger(printer: _LogPrinter());

  factory Logger() {
    var tmp = _instance;
    if (tmp == null) {
      tmp = Logger._();
      _instance = tmp;
    }
    return tmp;
  }
}

class _LogPrinter extends ex.PrettyPrinter {
  // Copied from package:logger/logger/printers/pretty_printer.dart
  static final _deviceStackTraceRegex = RegExp(r'#[0-9]+\s+(.+) \((\S+)\)');
  static final _webStackTraceRegex = RegExp(r'^((packages|dart-sdk)/\S+/)');
  static final _browserStackTraceRegex =
      RegExp(r'^(?:package:)?(dart:\S+|\S+)');

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
