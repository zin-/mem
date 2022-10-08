import 'package:flutter_test/flutter_test.dart';
import 'package:mem/repositories/log_repository.dart';

import '../_helpers.dart';

void main() {
  testLogRepository();
}

void testLogRepository() => group('LogRepository test', () {
      test(
        'Create instance',
        () {
          final logRepository = LogRepository();

          expect(logRepository, isA<LogRepository>());
        },
        tags: TestSize.small,
      );

      test(
        'Operation: receive',
        () {
          final logRepository = LogRepository();

          final log = LogEntity();

          logRepository.receive(log);
        },
        tags: TestSize.small,
      );
    });
