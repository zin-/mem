import 'package:mem/repositories/log_repository.dart';
import 'package:mem/services/log_service.dart';

const _filePath = 'mem/logger';

final logService = LogService(Level.trace, null, [_filePath]);

T v<T>(
  Map<String, dynamic>? arguments,
  T Function() function, {
  @Deprecated('Allow under develop only') bool debug = false,
}) =>
    logService.functionLog(
      function,
      arguments: arguments,
      level: debug ? Level.debug : Level.verbose,
    );

T t<T>(
  Map<String, dynamic>? args,
  T Function() function, {
  @Deprecated('Allow under develop only') bool debug = false,
}) =>
    logService.functionLog(
      function,
      arguments: args,
      level: debug ? Level.debug : Level.trace,
    );

T trace<T>(T object) {
  logService.log(object, level: Level.trace);
  return object;
}

T warn<T>(T object) {
  logService.log(object, level: Level.warning);
  return object;
}

@Deprecated('Allow under develop only')
T dev<T>(T object) {
  logService.log(object, level: Level.debug);
  return object;
}
