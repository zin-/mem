import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger/i/type.dart';
import 'package:mem/logger/log_repository.dart';

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
              );
            });

            group(': with StackTrace', () {
              test(
                ': default StackTrace',
                () {
                  final logRepository = LogRepository(Level.verbose);

                  final log = LogEntity('default StackTrace');

                  logRepository.receive(log);
                },
              );

              test(
                ': specify StackTrace',
                () {
                  final logRepository = LogRepository(Level.verbose);

                  final log = LogEntity(
                    'default StackTrace',
                    stackTrace: StackTrace.current,
                  );

                  logRepository.receive(log);
                },
              );

              test(
                ': specify StackTrace and Exception',
                () {
                  final logRepository = LogRepository(Level.verbose);

                  final log = LogEntity(
                    'default StackTrace',
                    stackTrace: StackTrace.current,
                    error: Exception('exception message with StackTrace'),
                  );

                  logRepository.receive(log);
                },
              );
            });
          });
        },
      );
    });
