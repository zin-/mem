
import 'package:mem/framework/repository.dart';

import 'log_entity.dart';
import 'logger_wrapper.dart';

class LogRepository extends RepositoryV3<Log, void> {
  LoggerWrapper _loggerWrapper;

  @override
  void receive(Log payload) => _loggerWrapper.log(
        payload.level,
        payload.message,
        payload.error,
        payload.stackTrace,
      );

  LogRepository._(this._loggerWrapper);

  static LogRepository? _instance;

  factory LogRepository(LoggerWrapper loggerWrapper) =>
      _instance ??= LogRepository._(
        loggerWrapper,
      );
}
