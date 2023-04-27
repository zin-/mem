import 'dart:async';

import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_repository_v2.dart';
import 'package:mem/logger/logger_wrapper_v2.dart';

dynamic v(
  dynamic target, [
  dynamic meta,
]) =>
    LogServiceV2()._log(Level.verbose, target, meta, null);

dynamic i(
  dynamic target, [
  dynamic meta,
]) =>
    LogServiceV2()._log(Level.info, target, meta, null);

@Deprecated('For development only')
dynamic d(
  dynamic target, [
  dynamic meta,
]) =>
    LogServiceV2()._log(Level.debug, target, meta, null);

class LogServiceV2 {
  final LogRepositoryV2 _logRepositoryV2;
  final Level _level;

  dynamic _log(
    Level level,
    dynamic target,
    dynamic meta,
    StackTrace? stackTrace, [
    List? prefixes,
  ]) {
    if (target is Future) {
      _futureLog(level, target, meta, stackTrace, prefixes);
      return target;
    } else if (target is Function()) {
      return _functionLog(level, target, meta);
    }

    if (_shouldLog(level)) {
      final message = (prefixes ?? []
        ..add(target.toString()));
      if (DebugLoggableFunction._debug) {
        message.insert(0, '[DEBUG]');
      }
      _logRepositoryV2.receive(Log(level, message.join(), meta, stackTrace));
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
    final currentStackTrace = StackTrace.current;

    await target.then((result) {
      _log(
        level,
        result,
        meta,
        currentStackTrace,
        prefixes ?? []
          ..add('[future] : '),
      );
    });

    return target;
  }

  Result _functionLog<Result>(
    Level level,
    Result Function() function,
    dynamic args,
  ) {
    try {
      _log(level, args, null, null, ['[start] :: ']);
      final result = function.callWithDebug(level == Level.debug);
      const endPrefix = '[ end ] => ';
      if (function is Null Function()) {
        _log(level, 'void', null, null, [endPrefix]);
      } else if (result is Future) {
        _log(level, result, null, null, [endPrefix]);
      } else {
        _log(level, result, null, null, [endPrefix]);
      }
      return result;
    } catch (e) {
      _log(Level.error, 'Thrown is caught.', e, null);
      rethrow;
    }
  }

  bool _shouldLog(Level level) =>
      DebugLoggableFunction._debug || _level.index <= level.index;

  LogServiceV2._(this._logRepositoryV2, this._level);

  static LogServiceV2? _instance;

  factory LogServiceV2.initialize(Level level) {
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
