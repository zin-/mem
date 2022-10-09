import 'package:mem/repositories/log_repository.dart';

const _filePath = 'mem/services/log_service.dart';

class LogService {
  final Level _level;
  final LogRepository _logRepository;

  LogService._(this._level, this._logRepository);

  log(dynamic message, {Level? level}) {
    final log = LogEntity(message, level: level);
    if (log.level.index >= _level.index) {
      // TODO error
      _logRepository.receive(log);
    }
  }

  static LogService? _instance;

  factory LogService([Level? level, LogRepository? logRepository]) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = LogService._(
        level ?? Level.error,
        logRepository ?? LogRepository(level ?? Level.error, [_filePath]),
      );
      _instance = tmp;
    }
    return tmp;
  }

  static reset() {
    LogRepository.reset();
    _instance = null;
  }
}
