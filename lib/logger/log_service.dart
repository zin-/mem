import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_repository.dart';
import 'package:mem/logger/logger_wrapper.dart';

T verbose<T>(T target) => LogService().valueLog(Level.verbose, target);

T info<T>(T target) => LogService().valueLog(Level.info, target);

T warn<T>(T target) => LogService().valueLog(Level.warning, target);

@Deprecated('For development only')
T debug<T>(T target) => LogService().valueLog(Level.debug, target);

T v<T>(
  T Function() target, [
  dynamic args,
]) =>
    LogService().functionLog(Level.verbose, target, args);

T i<T>(
  T Function() target, [
  dynamic args,
]) =>
    LogService().functionLog(Level.info, target, args);

T w<T>(
  T Function() target, [
  dynamic args,
]) =>
    LogService().functionLog(Level.warning, target, args);

@Deprecated('For development only')
T d<T>(
  T Function() target, [
  dynamic args,
]) =>
    LogService().functionLog(Level.debug, target, args);

class LogService {
  final LogRepository _repository;
  final Level _level;

  T valueLog<T>(
    Level level,
    T target, {
    List<String>? prefixes,
    StackTrace? stackTrace,
    bool autoDebug = false,
  }) {
    final tmpPrefixes = prefixes ?? [];
    if (target is Future) {
      _futureLog(level, target, tmpPrefixes);
    } else {
      if (autoDebug || _shouldLog(level)) {
        if (autoDebug || _DebugLoggableFunction._debug) {
          tmpPrefixes.insert(0, '** [AUTO DEBUG] ** ');
        }
        _repository.receive(Log(
          level,
          [
            tmpPrefixes.join(),
            target ?? 'no message.',
          ].join(),
          null,
          stackTrace,
        ));
      }
    }

    return target;
  }

  T functionLog<T>(Level level, T Function() function, [dynamic args]) {
    valueLog(level, args.toString(), prefixes: ['[start] :: ']);

    try {
      final result = function._callWithDebug(level == Level.debug);

      valueLog(level, result, prefixes: ['[end] => ']);

      return result;
    } catch (e, stackTrace) {
      _errorLog(e, stackTrace);
      rethrow;
    }
  }

  void _futureLog<T>(
    Level level,
    Future<T> target,
    List<String>? prefixes,
  ) {
    if (_shouldLog(level)) {
      final currentStackTrace = StackTrace.current;
      final autoDebug = _DebugLoggableFunction._debug;

      target.then(
        (value) => valueLog(
          level,
          value,
          prefixes: (prefixes ?? [])..add('[future] >> '),
          stackTrace: currentStackTrace,
          autoDebug: autoDebug,
        ),
        onError: (error, stackTrace) => _errorLog(error, stackTrace),
      );
    } else {
      target.then(
        (value) {},
        onError: (error, stackTrace) => _errorLog(error, stackTrace),
      );
    }
  }

  _errorLog(dynamic e, [StackTrace? stackTrace]) => _repository.receive(
        Log(
          Level.error,
          '[error] !!',
          e,
          stackTrace,
        ),
      );

  bool _shouldLog(Level level) =>
      _DebugLoggableFunction._debug || level.index >= _level.index;

  LogService._(this._repository, this._level);

  static LogService? _instance;

  factory LogService.initialize([Level level = Level.info]) =>
      _instance = LogService._(
        LogRepository(
            // TODO CICDであることを受け渡す
            LoggerWrapper()
        ),
        level,
      );

  factory LogService() {
    var tmp = _instance;

    if (tmp == null) {
      return LogService.initialize();
    } else {
      return tmp;
    }
  }
}

extension _DebugLoggableFunction on Function {
  static bool _debug = false;

  _callWithDebug(bool debug) {
    _debug = _debug || debug;
    final result = call();
    if (debug) _debug = false;
    return result;
  }
}
