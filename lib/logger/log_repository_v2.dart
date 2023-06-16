import 'package:mem/framework/repository_v3.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/logger_wrapper_v2.dart';

class LogRepositoryV2 extends RepositoryV3<Log, void> {
  LoggerWrapperV2 _loggerWrapper;

  @override
  void receive(Log payload) => _loggerWrapper.log(
        payload.level,
        payload.message,
        payload.error,
        payload.stackTrace,
      );

  LogRepositoryV2._(this._loggerWrapper);

  static LogRepositoryV2? _instance;

  factory LogRepositoryV2(LoggerWrapperV2 loggerWrapperV2) {
    var tmp = _instance;

    if (tmp == null) {
      _instance = tmp = LogRepositoryV2._(
        loggerWrapperV2,
      );
    }

    return tmp;
  }
}
