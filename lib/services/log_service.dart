import 'package:mem/repositories/log_repository.dart';

const _filePath = 'mem/services/log_service.dart';

class LogService {
  final Level _level;
  final LogRepository _logRepository;
  bool _debug = false;

  LogService._(this._level, this._logRepository);

  log(dynamic message, {dynamic error, Level? level, StackTrace? stackTrace}) {
    final log = LogEntity(
      message,
      error: error,
      level: level,
      stackTrace: stackTrace,
    );
    if (_shouldLog(log.level)) {
      _logRepository.receive(log);
    }
  }

  T functionLog<T>(
    T Function() function, {
    Map<String, dynamic>? args,
    Level? level,
  }) {
    if (_shouldLog(level) || _debug) {
      if (_debug) level = Level.debug;

      final current = StackTrace.current;

      log(
        '${_debug ? '[AUTO DEBUG] ' : ''}'
        'start${args == null ? '' : ' :: $args'}',
        level: level,
        stackTrace: current,
      );

      if (level == Level.debug) _debug = true;

      try {
        final result = function();

        if (result is Future) {
          result.then((value) => log(
                '${_debug ? '[AUTO DEBUG] ' : ''}'
                'end => Future${value == null ? '' : ' => $value'}',
                level: level,
                stackTrace: current,
              ));
        } else {
          log(
            '${_debug ? '[AUTO DEBUG] ' : ''}'
            'end${result == null ? '' : ' => $result'}',
            level: level,
          );
        }

        if (level == Level.debug) _debug = false;
        return result;
      } catch (e) {
        log('Caught', error: e, stackTrace: current);
        rethrow;
      }
    }

    return function();
  }

  bool _shouldLog(Level? level) => _level.index <= (level?.index ?? 0);

  static LogService? _instance;

  factory LogService([Level? level, LogRepository? logRepository]) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = LogService._(
        level ?? Level.error,
        logRepository ?? LogRepository(level ?? Level.error, [_filePath]),
      );
      _instance = tmp;
    }
    return tmp;
  }

  static reset() {
    LogRepository.reset();
    _instance = null;
  }
}
