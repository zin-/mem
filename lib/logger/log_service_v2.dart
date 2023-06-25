import 'dart:async';

import 'package:mem/logger/i/api.dart';
import 'package:mem/logger/i/type.dart' as v1;
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_repository_v2.dart';
import 'package:mem/logger/logger_wrapper_v2.dart';

T verbose<T>(
  T target, [
  dynamic meta,
]) =>
    LogServiceV2()._log(Level.verbose, target, meta, null, []);

T info<T>(
  T target, [
  dynamic meta,
]) =>
    LogServiceV2()._log(Level.info, target, meta, null, []);

T warn<T>(
  T target, [
  dynamic meta,
]) =>
    LogServiceV2()._log(Level.warning, target, meta, null, []);

@Deprecated('For development only')
T debug<T>(
  T target, [
  dynamic meta,
]) =>
    LogServiceV2()._log(Level.debug, target, meta, null, []);

T v<T>(
  T Function() target, [
  dynamic meta,
]) =>
    LogServiceV2()._functionLog(Level.verbose, target, meta);

T i<T>(
  T Function() target, [
  dynamic meta,
]) =>
    LogServiceV2()._functionLog(Level.info, target, meta);

T w<T>(
  T Function() target, [
  dynamic meta,
]) =>
    LogServiceV2()._functionLog(Level.warning, target, meta);

@Deprecated('For development only')
T d<T>(
  T Function() target, [
  dynamic meta,
]) =>
    LogServiceV2()._functionLog(Level.debug, target, meta);

class LogServiceV2 {
  final LogRepositoryV2 _logRepositoryV2;
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

      _logRepositoryV2.receive(Log(
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

  LogServiceV2._(this._logRepositoryV2, this._level);

  static LogServiceV2? _instance;

  factory LogServiceV2.initialize(Level level) {
    if (level == Level.verbose) {
      initializeLogger(v1.Level.verbose);
    }

    return _instance = LogServiceV2._(
      LogRepositoryV2(LoggerWrapperV2()),
      level,
    );
  }

  factory LogServiceV2() {
    var tmp = _instance;

    if (tmp == null) {
      return LogServiceV2.initialize(Level.info);
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
