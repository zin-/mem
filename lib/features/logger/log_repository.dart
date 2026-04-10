import 'dart:async';

import 'package:mem/framework/repository/repository.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mem/features/logger/sentry_wrapper.dart';

import 'log.dart';
import 'logger_wrapper.dart';

class LogRepository extends Repository {
  final LoggerWrapper _loggerWrapper;
  final SentryWrapper? _sentryWrapper;

  Future<void> init(
    FutureOr<void> Function() appRunner,
  ) async {
    if (_sentryWrapper == null) {
      await appRunner();
    } else {
      await _sentryWrapper.init(appRunner); // coverage:ignore-line
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

  factory LogRepository(
    LoggerWrapper loggerWrapper,
    SentryWrapper? sentryWrapper,
  ) =>
      Singleton.of(
        () => LogRepository._(
          loggerWrapper,
          sentryWrapper,
        ),
      );
}
