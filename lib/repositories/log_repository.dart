import 'package:mem/repositories/_repository.dart';
import 'package:mem/wrappers/logger.dart';

const _filePath = 'mem/repositories/log_repository.dart';

class LogRepository extends Repository<LogEntity, void> {
  final LoggerWrapper _loggerWrapper;

  LogRepository._(this._loggerWrapper);

  @override
  void receive(LogEntity entity) {
    _loggerWrapper.log(entity.level, entity.message);
  }

  static LogRepository? _instance;

  factory LogRepository(Level level) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = LogRepository._(
        LoggerWrapper(
          level,
          _shouldOutputDeviceStacktraceLine,
        ),
      );
      _instance = tmp;
    }
    return tmp;
  }

  static reset() {
    LoggerWrapper.reset();
    _instance = null;
  }

  static bool _shouldOutputDeviceStacktraceLine(String line, String filePath) {
    // FIXME おそらくWebだと抽出方法が異なる
    var match = RegExp(r'#[0-9]+\s+(.+) \((\S+)\)').matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final reference = match.group(2);

    if (reference == null) {
      return true;
    }
    for (final filePath in [filePath, _filePath]) {
      final startsWith = reference.startsWith('package:$filePath');
      if (startsWith) {
        return false;
      }
    }
    return true;
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
