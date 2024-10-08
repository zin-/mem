import 'dart:async';

import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/sentry_wrapper.dart';

import 'log.dart';
import 'logger_wrapper.dart';

class LogRepository extends Repository<Log> {
  final LoggerWrapper _loggerWrapper;
  final SentryWrapper? _sentryWrapper;

  Future<void> init(
    FutureOr<void> Function() appRunner,
  ) async {
    if (_sentryWrapper == null) {
      await appRunner();
    } else {
      await _sentryWrapper.init(appRunner);
    }
  }

  Future<void> receive(Log entity) async {
    _loggerWrapper.log(
      entity.level,
      entity.buildMessage(),
      entity.error,
      entity.stackTrace,
    );

    if (_sentryWrapper != null &&
        Level.warning.index <= entity.level.index &&
        entity.level.index < Level.debug.index) {
      await _sentryWrapper.captureException(entity.error, entity.stackTrace);
    }
  }

  LogRepository._(
    this._loggerWrapper,
    this._sentryWrapper,
  );

  static LogRepository? _instance;

  factory LogRepository(
    LoggerWrapper loggerWrapper,
    SentryWrapper? sentryWrapper,
  ) =>
      _instance ??= LogRepository._(
        loggerWrapper,
        sentryWrapper,
      );
}
