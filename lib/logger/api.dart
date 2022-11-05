import 'package:mem/logger.dart';
import 'package:mem/repositories/log_repository.dart';

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
