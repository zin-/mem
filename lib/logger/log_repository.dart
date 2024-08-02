import 'package:mem/framework/repository/repository.dart';

import 'log.dart';
import 'logger_wrapper.dart';

class LogRepository extends RepositoryV2<Log> with Receiver<Log, void> {
  LoggerWrapper _loggerWrapper;

  @override
  Future<void> receive(Log entity) async => _loggerWrapper.log(
        entity.level,
        entity.buildMessage(),
        entity.error,
        entity.stackTrace,
      );

  LogRepository._(this._loggerWrapper);

  static LogRepository? _instance;

  factory LogRepository(LoggerWrapper loggerWrapper) =>
      _instance ??= LogRepository._(loggerWrapper);
}
