
import 'package:mem/framework/repository/repository.dart';

import 'log_entity.dart';
import 'logger_wrapper.dart';

class LogRepository extends Repository<Log> {
  LoggerWrapper _loggerWrapper;

  @override
  void receive(Log entity) => _loggerWrapper.log(
        entity.level,
        entity.message,
        entity.error,
        entity.stackTrace,
      );

  LogRepository._(this._loggerWrapper);

  static LogRepository? _instance;

  factory LogRepository(LoggerWrapper loggerWrapper) =>
      _instance ??= LogRepository._(
        loggerWrapper,
      );
}
