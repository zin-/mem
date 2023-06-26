import 'package:flutter/foundation.dart';
import 'package:mem/logger/log_service.dart';

import 'type.dart';

const _filePath = 'mem/logger/i/api.dart';

LogService _logService = LogService(
  Level.error,
  ignoreFilePaths: [_filePath],
);

void initializeLogger([Level? logLevel]) {
  LogService.reset();
  _logService = LogService(
    logLevel ?? (kDebugMode ? Level.trace : Level.error),
    ignoreFilePaths: [_filePath],
  );
}

T verbose<T>(T message) {
  _logService.log(message, level: Level.verbose);
  return message;
}

T trace<T>(T message) {
  _logService.log(message, level: Level.trace);
  return message;
}

T warn<T>(T message) {
  _logService.log(message, level: Level.warning);
  return message;
}

// coverage:ignore-start
@Deprecated('Allow under develop only')
T? dev<T>([T? message]) {
  _logService.log(message ?? 'Under development.', level: Level.debug);
  return message;
}
// coverage:ignore-end
