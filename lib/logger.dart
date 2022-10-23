import 'package:flutter/foundation.dart';
import 'package:mem/repositories/log_repository.dart';
import 'package:mem/services/log_service.dart';

const _filePath = 'mem/logger';

LogService _logService = LogService(
  (kDebugMode ? Level.trace : Level.error),
  ignoreFilePaths: [_filePath],
);

void initializeLogger([Level? logLevel]) {
  LogService.reset();
  _logService = LogService(
    logLevel ?? (kDebugMode ? Level.trace : Level.error),
    ignoreFilePaths: [_filePath],
  );
}

T v<T>(
  Map<String, dynamic>? arguments,
  T Function() function, {
  @Deprecated('Allow under develop only') bool debug = false,
}) =>
    _logService.functionLog(
      function,
      arguments: arguments,
      level: debug ? Level.debug : Level.verbose,
    );

T t<T>(
  Map<String, dynamic>? args,
  T Function() function, {
  @Deprecated('Allow under develop only') bool debug = false,
}) =>
    _logService.functionLog(
      function,
      arguments: args,
      level: debug ? Level.debug : Level.trace,
    );

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
T dev<T>([T? message]) {
  _logService.log(message ?? 'Under development.', level: Level.debug);
  return message as T;
}
// coverage:ignore-end
