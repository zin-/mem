import 'package:mem/framework/repository_v3.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/logger_wrapper.dart';

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

  factory LogRepository(LoggerWrapper loggerWrapper) {
    var tmp = _instance;

    if (tmp == null) {
      _instance = tmp = LogRepository._(
        loggerWrapper,
      );
    }

    return tmp;
  }
}
