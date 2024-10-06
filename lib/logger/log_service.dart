import 'package:mem/logger/sentry_wrapper.dart';

import 'log.dart';
import 'log_repository.dart';
import 'logger_wrapper.dart';

T verbose<T>(T target) => LogService().valueLog(Level.verbose, target);

T info<T>(T target) => LogService().valueLog(Level.info, target);

T warn<T>(T target) => LogService().valueLog(Level.warning, target);

@Deprecated("For development only")
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

@Deprecated("Use for development only")
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
        Level tmpLevel = level;

        if (autoDebug || _DebugLoggableFunction._debug) {
          tmpPrefixes.insert(0, "** [AUTO DEBUG] ** ");
          tmpLevel = Level.debug;
        }

        _repository.receive(
          Log(
            tmpLevel,
            tmpPrefixes,
            target,
            null,
            stackTrace,
          ),
        );
      }
    }

    return target;
  }

  T functionLog<T>(Level level, T Function() function, [dynamic args]) {
    valueLog(level, args, prefixes: ["[start] :: "]);

    try {
      final result = function._callWithDebug(level == Level.debug);

      valueLog(level, result, prefixes: ["[end] => "]);

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
          prefixes: (prefixes ?? [])..add("[future] >> "),
          stackTrace: currentStackTrace,
          autoDebug: autoDebug,
        ),
        onError: (error, stackTrace) => _errorLog(error, stackTrace),
      );
    } else {
      target.onError(
        (error, stackTrace) => _errorLog(error, stackTrace),
      );
    }
  }

  _errorLog(
    dynamic e, [
    StackTrace? stackTrace,
  ]) =>
      _repository.receive(
        Log(
          Level.error,
          [
            "[error] !!",
          ],
          "",
          e,
          stackTrace,
        ),
      );

  bool _shouldLog(Level level) =>
      _DebugLoggableFunction._debug || level.index >= _level.index;

  LogService._(this._repository, this._level);

  static LogService? _instance;

  factory LogService.initialize({
    Level level = Level.info,
    bool enableSimpleLog = false,
  }) =>
      _instance = LogService._(
        LogRepository(
          LoggerWrapper(enableSimpleLog),
          SentryWrapper(),
        ),
        level,
      );

  factory LogService() => _instance ??= LogService.initialize();
}

extension _DebugLoggableFunction<T> on T Function() {
  static bool _debug = false;

  T _callWithDebug(bool debug) {
    _debug = _debug || debug;
    final result = call();
    if (debug) _debug = false;
    return result;
  }
}
