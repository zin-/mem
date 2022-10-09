import 'package:flutter_test/flutter_test.dart';
import 'package:mem/repositories/log_repository.dart';

import '../_helpers.dart';

void main() {
  testLogRepository();
}

void testLogRepository() => group('LogRepository test', () {
      tearDown(() {
        LogRepository.reset();
      });

      test(
        'Create instance',
        () {
          final logRepository = LogRepository(Level.error);

          expect(logRepository, isA<LogRepository>());
        },
        tags: TestSize.small,
      );

      group(
        'Operation',
        () {
          group(': receive', () {
            for (final logLevel in Level.values) {
              group(': log level is $logLevel', () {
                final logRepository = LogRepository(logLevel);

                for (final level in Level.values) {
                  test(
                    ': message level is $level',
                    () {
                      final log = LogEntity(
                        'test message: level is $level',
                        level,
                      );

                      logRepository.receive(log);
                    },
                    tags: TestSize.small,
                  );
                }
              });
            }

            test(
              ': default level is verbose',
              () {
                final logRepository = LogRepository(Level.verbose);

                final log = LogEntity('default level is verbose');

                logRepository.receive(log);
              },
              tags: TestSize.small,
            );
          });
        },
      );
    });
