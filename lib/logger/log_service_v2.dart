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

dynamic d(
  dynamic target, [
  dynamic meta,
]) =>
    LogServiceV2()._log(Level.debug, target, meta, null);

/// 処理を記録する
///
/// # 検討
/// ## ロガーを複数持つ
/// 開発・デバッグ・テストのために出力したいログと、運用のために出力したいログは異なる
class LogServiceV2 {
  final LogRepositoryV2 _logRepositoryV2;
  final Level _level;

  dynamic _log(
    Level level,
    dynamic target,
    dynamic meta,
    // FIXME これいるか？
    StackTrace? stackTrace,
  ) {
    if (target is Future) {
      _futureLog(level, target, meta, stackTrace);
      return target;
    }

    if (_shouldLog(level)) {
      _logRepositoryV2.receive(Log(level, target, meta, stackTrace));
    }

    return target;
  }

  Future<Result> _futureLog<Result>(
    Level level,
    Future<Result> target,
    dynamic meta,
    StackTrace? stackTrace,
  ) async {
    final currentStackTrace = StackTrace.current;

    await target.then((result) {
      _log(level, '[future] $result', meta, currentStackTrace);
    }).catchError((error) {
      _log(Level.error, 'future error', error, currentStackTrace);
      throw error;
    });

    return target;
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
