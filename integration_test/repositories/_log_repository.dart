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

      group(
        'Operation',
        () {
          final logRepository = LogRepository();

          for (final level in Level.values) {
            test(
              'receive: log level is $level',
              () {
                final log = LogEntity(
                  Level.verbose,
                  'test message: level is $level',
                );

                logRepository.receive(log);
              },
              tags: TestSize.small,
            );
          }
        },
      );
    });
