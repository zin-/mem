import 'dart:async';

import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_repository.dart';
import 'package:mem/logger/logger_wrapper.dart';

T verbose<T>(
  T target, [
  dynamic meta,
]) =>
    LogService()._log(Level.verbose, target, meta, null, []);

T info<T>(
  T target, [
  dynamic meta,
]) =>
    LogService()._log(Level.info, target, meta, null, []);

T warn<T>(
  T target, [
  dynamic meta,
]) =>
    LogService()._log(Level.warning, target, meta, null, []);

@Deprecated('For development only')
T debug<T>(
  T target, [
  dynamic meta,
]) =>
    LogService()._log(Level.debug, target, meta, null, []);

T v<T>(
  T Function() target, [
  dynamic meta,
]) =>
    LogService()._functionLog(Level.verbose, target, meta);

T i<T>(
  T Function() target, [
  dynamic meta,
]) =>
    LogService()._functionLog(Level.info, target, meta);

T w<T>(
  T Function() target, [
  dynamic meta,
]) =>
    LogService()._functionLog(Level.warning, target, meta);

@Deprecated('For development only')
T d<T>(
  T Function() target, [
  dynamic meta,
]) =>
    LogService()._functionLog(Level.debug, target, meta);

class LogService {
  final LogRepository _logRepository;
  final Level _level;

  dynamic _log(
    Level level,
    dynamic target,
    dynamic meta,
    StackTrace? stackTrace,
    List prefixes,
  ) {
    if (_shouldLog(level)) {
      if (target is Future) {
        _futureLog(level, target, meta, stackTrace, prefixes);
        return target;
      }

      if (DebugLoggableFunction._debug) {
        prefixes.insert(0, '[DEBUG]');
      }

      _logRepository.receive(Log(
          level,
          [
            prefixes.join(),
            target.toString(),
          ].join(),
          meta,
          stackTrace));
    }

    return target;
  }

  Future<Result> _futureLog<Result>(
    Level level,
    Future<Result> target,
    dynamic meta,
    StackTrace? stackTrace, [
    List? prefixes,
  ]) async {
    if (_shouldLog(level)) {
      final currentStackTrace = StackTrace.current;
      final result = await target;

      _log(
        level,
        result,
        meta,
        currentStackTrace,
        (prefixes ?? [])..add('[future] => '),
      );
    }

    return target;
  }

  Result _functionLog<Result>(
    Level level,
    Result Function() function,
    dynamic args,
  ) {
    try {
      if (_shouldLog(level)) {
        _log(level, args, null, null, ['[start] :: ']);
      }

      final result = function.callWithDebug(level == Level.debug);

      if (_shouldLog(level)) {
        _log(level, result, null, null, ['[ end ] => ']);
      }
      return result;
    } catch (e) {
      _log(Level.error, 'Thrown is caught.', e, null, []);
      rethrow;
    }
  }

  // TODO Widgetのbuildを自動debugログの対象にする
  bool _shouldLog(Level level) =>
      DebugLoggableFunction._debug || _level.index <= level.index;

  LogService._(this._logRepository, this._level);

  static LogService? _instance;

  factory LogService.initialize(Level level) {
    return _instance = LogService._(
      LogRepository(LoggerWrapper()),
      level,
    );
  }

  factory LogService() {
    var tmp = _instance;

    if (tmp == null) {
      return LogService.initialize(Level.info);
    } else {
      return tmp;
    }
  }
}

extension DebugLoggableFunction on Function {
  static bool _debug = false;

  callWithDebug(bool debug) {
    _debug = _debug || debug;
    final result = call();
    if (debug) _debug = false;
    return result;
  }
}
