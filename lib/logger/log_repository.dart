import 'package:mem/framework/repository/repository.dart';

import 'log_entity.dart';
import 'logger_wrapper.dart';

class LogRepositoryV1 extends RepositoryV1<LogV1, void> {
  LoggerWrapper _loggerWrapper;

  @override
  Future<void> receive(LogV1 entity) async => _loggerWrapper.log(
        entity.level,
        entity.message,
        entity.error,
        entity.stackTrace,
      );

  LogRepositoryV1._(this._loggerWrapper);

  static LogRepositoryV1? _instance;

  factory LogRepositoryV1(LoggerWrapper loggerWrapper) =>
      _instance ??= LogRepositoryV1._(
        loggerWrapper,
      );
}
