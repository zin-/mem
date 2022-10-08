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

  factory LogRepository([Level? level, LoggerWrapper? loggerWrapper]) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = LogRepository._(
        loggerWrapper ?? LoggerWrapper(level ?? Level.debug),
      );
      _instance = tmp;
    }
    return tmp;
  }

  factory LogRepository.reset([Level? level]) {
    _instance = null;
    return LogRepository(
      level,
      LoggerWrapper.reset(level ?? Level.debug),
    );
  }
}

enum Level {
  verbose,
  trace,
  warning,
  error,
  debug,
}

class LogEntity extends Entity {
  Level level;
  dynamic message;

  LogEntity(this.level, this.message);
}
