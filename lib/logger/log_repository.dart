import 'package:mem/repositories/_repository.dart';
import 'package:mem/logger/logger.dart';

import 'i/type.dart';

const _filePath = 'mem/repositories/log_repository.dart';

class LogRepository extends Repository<LogEntity, void> {
  final LoggerWrapper _loggerWrapper;

  LogRepository._(this._loggerWrapper);

  @override
  void receive(LogEntity entity) {
    _loggerWrapper.log(
      entity.level,
      entity.message,
      entity.error,
      entity.stackTrace,
    );
  }

  static LogRepository? _instance;

  factory LogRepository(Level level, [Iterable<String>? ignoreFilePaths]) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = LogRepository._(
        LoggerWrapper(
          level,
          _shouldOutputDeviceStacktraceLine(
            [_filePath, ...ignoreFilePaths ?? []],
          ),
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

  static bool Function(
    String line,
    String ignoreFilePath,
  ) _shouldOutputDeviceStacktraceLine(Iterable<String> ignoreFilePaths) {
    return (String line, String ignoreFilePath) {
      // FIXME おそらくWebだと抽出方法が異なる
      var match = RegExp(r'#[0-9]+\s+(.+) \((\S+)\)').matchAsPrefix(line);
      if (match == null) {
        return false;
      }
      final reference = match.group(2);

      if (reference == null) {
        return true;
      }
      for (final filePath in [ignoreFilePath, ...ignoreFilePaths]) {
        final startsWith = reference.startsWith('package:$filePath');
        if (startsWith) {
          return false;
        }
      }
      return true;
    };
  }
}

class LogEntity extends Entity {
  final dynamic message; // FIXME dynamicで良いのか？
  final dynamic error;
  late final StackTrace stackTrace;
  late final Level level;

  LogEntity(this.message, {StackTrace? stackTrace, this.error, Level? level}) {
    this.stackTrace = stackTrace ?? StackTrace.current;
    this.level = level ??
        (error is Error
            ? Level.error
            : error is Exception
                ? Level.warning
                : Level.verbose);
  }
}
