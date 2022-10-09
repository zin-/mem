import 'package:flutter_test/flutter_test.dart';
import 'package:mem/repositories/log_repository.dart';

import '../_helpers.dart';

void main() {
  testLogRepository();
}

void testLogRepository() => group('LogRepository test', () {
      tearDownAll(() {
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
                LogRepository.reset();
                final logRepository = LogRepository(logLevel);

                for (final level in Level.values) {
                  test(
                    ': message level is $level',
                    () {
                      final log = LogEntity(
                        'test message: level is $level',
                        level: level,
                      );

                      logRepository.receive(log);
                    },
                    tags: TestSize.small,
                  );
                }
              });
            }

            setUp(() {
              LogRepository.reset();
            });

            test(
              ': default message level is verbose',
              () {
                final logRepository = LogRepository(Level.verbose);

                final log = LogEntity('default level is verbose');

                logRepository.receive(log);
              },
              tags: TestSize.small,
            );

            group(': with Error', () {
              test(
                ': default message level is error',
                () {
                  final logRepository = LogRepository(Level.verbose);

                  final log = LogEntity(
                    'default level is error',
                    error: Error(),
                  );

                  logRepository.receive(log);
                },
                tags: TestSize.small,
              );

              test(
                ': specify message level is verbose',
                () {
                  final logRepository = LogRepository(Level.verbose);

                  final log = LogEntity(
                    'specify level is verbose',
                    error: Error(),
                    level: Level.verbose,
                  );

                  logRepository.receive(log);
                },
                tags: TestSize.small,
              );
            });

            group(': with Exception', () {
              test(
                ': default message level is warning',
                () {
                  final logRepository = LogRepository(Level.verbose);

                  final log = LogEntity(
                    'default level is warning',
                    error: Exception('test exception message'),
                  );

                  logRepository.receive(log);
                },
                tags: TestSize.small,
              );

              test(
                ': specify message level is verbose',
                () {
                  final logRepository = LogRepository(Level.verbose);

                  final log = LogEntity(
                    'specify level is verbose',
                    error: Exception('test exception message'),
                    level: Level.verbose,
                  );

                  logRepository.receive(log);
                },
                tags: TestSize.small,
              );
            });
          });
        },
      );
    });
