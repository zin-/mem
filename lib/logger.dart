import 'package:mem/repositories/log_repository.dart';
import 'package:mem/services/log_service.dart';

LogService _logService = LogService(Level.error);

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

// TODO 引数もログに表示されるようにしたい
// T vV2<T>(T Function() function) {
//   return function();
// }

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
T? dev<T>([T? message]) {
  _logService.log(message ?? 'Under development.', level: Level.debug);
  return message;
}
// coverage:ignore-end
