import 'package:mem/repositories/_repository.dart';
import 'package:mem/wrappers/logger.dart';

class LogRepository extends Repository<LogEntity, void> {
  final LoggerWrapper _loggerWrapper;

  LogRepository._(this._loggerWrapper);

  @override
  void receive(LogEntity entity) {
    _loggerWrapper.log(entity.level, entity.message);
  }

  static LogRepository? _instance;

  factory LogRepository() {
    var tmp = _instance;
    if (tmp == null) {
      tmp = LogRepository._(
        LoggerWrapper(),
      );
      _instance = tmp;
    }
    return tmp;
  }
}

enum Level {
  verbose,
  debug,
}

class LogEntity extends Entity {
  Level level;
  dynamic message;

  LogEntity(this.level, this.message);
}
