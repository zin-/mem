import 'package:flutter_test/flutter_test.dart';
import 'package:mem/repositories/log_repository.dart';
import 'package:mem/services/log_service.dart';

import '_helpers.dart';

void main() {
  final logService = LogService();

  test(
    'log',
    () {
      const level = Level.error;
      const message = 'test message';

      logService.log(level, message);
    },
    tags: TestSize.small,
  );
}
