import 'package:mem/repositories/log_repository.dart';

const _filePath = 'mem/services/log_service.dart';

class LogService {
  final Level _level; // TODO ここから
  final LogRepository _logRepository;

  LogService._(this._level, this._logRepository);

  log(Level level, dynamic message) {
    _logRepository.receive(LogEntity(level, message));
  }

  static LogService? _instance;

  factory LogService([Level? level]) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = LogService._(
        level ?? Level.error,
        LogRepository(level ?? Level.error, [_filePath]),
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
