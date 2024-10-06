import 'package:mem/framework/repository/repository.dart';
import 'package:mem/logger/sentry_wrapper.dart';

import 'log.dart';
import 'logger_wrapper.dart';

class LogRepository extends Repository<Log> {
  LoggerWrapper _loggerWrapper;
  SentryWrapper _sentryWrapper;

  Future<void> receive(Log entity) async {
    _loggerWrapper.log(
      entity.level,
      entity.buildMessage(),
      entity.error,
      entity.stackTrace,
    );

    if (Level.warning.index <= entity.level.index &&
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
    SentryWrapper sentryWrapper,
  ) =>
      _instance ??= LogRepository._(
        loggerWrapper,
        sentryWrapper,
      );
}
