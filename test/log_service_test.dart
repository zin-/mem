import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger/i/type.dart';
import 'package:mem/logger/log_repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<LogRepository>(),
])
import 'log_service_test.mocks.dart';

void main() {
  final mockedLogRepository = MockLogRepository();

  setUp(() {
    LogService.reset();

    reset(mockedLogRepository);
  });

  test('Create instance', () {
    final logService = LogService(Level.error);

    expect(logService, isA<LogService>());
  });

  group('log', () {
    group(': call when message level is greater than log level', () {
      final logService = LogService(
        Level.error,
        logRepository: mockedLogRepository,
      );

      test(
        ': message level debug',
        () {
          const level = Level.debug;
          const message = 'test message';

          when(mockedLogRepository.receive(any)).thenAnswer((realInvocation) {
            expect(realInvocation.positionalArguments.length, 1);

            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, isA<LogEntity>());
            expect(arg1.message, message);
            expect(arg1.level, level);
            expect(arg1.error, null);
          });

          logService.log(message, level: level);

          verify(mockedLogRepository.receive(any)).called(1);
        },
      );

      test(
        ': message level error',
        () {
          const message = 'test message';
          final error = Error();

          when(mockedLogRepository.receive(any)).thenAnswer((realInvocation) {
            expect(realInvocation.positionalArguments.length, 1);

            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, isA<LogEntity>());
            expect(arg1.message, message);
            expect(arg1.level, Level.error);
            expect(arg1.error, error);
          });

          logService.log(message, error: error);

          verify(mockedLogRepository.receive(any)).called(1);
        },
      );

      test(
        ': message level warning',
        () {
          const message = 'test message';
          final exception = Exception('test exception message');

          when(mockedLogRepository.receive(any)).thenAnswer((realInvocation) {
            expect(realInvocation.positionalArguments.length, 1);

            final arg1 = realInvocation.positionalArguments[0];

            expect(arg1, isA<LogEntity>());
            expect(arg1.message, message);
            expect(arg1.level, Level.warning);
            expect(arg1.error, exception);
          });

          logService.log(message, error: exception);

          verifyNever(mockedLogRepository.receive(any));
        },
      );
    });
  });

  group('functionLog', () {
    test(
      'message level is less than log level',
      () {
        LogService.reset();
        final logService = LogService(
          Level.error,
          logRepository: mockedLogRepository,
        );

        void testFunction() {}

        logService.functionLog(testFunction, level: Level.verbose);

        verifyNever(mockedLogRepository.receive(any));
      },
    );

    LogService.reset();
    final logService = LogService(
      Level.verbose,
      logRepository: mockedLogRepository,
    );

    group(': sync function', () {
      group(': no args', () {
        test(
          ': no returns',
          () {
            void testFunction() {}

            final expectedMessages = ['start', 'end'];

            when(mockedLogRepository.receive(any)).thenAnswer((realInvocation) {
              expect(realInvocation.positionalArguments.length, 1);

              final arg1 = realInvocation.positionalArguments[0];
              expect(arg1, isA<LogEntity>());
              expect(arg1.message, expectedMessages.removeAt(0));
            });

            logService.functionLog(testFunction);

            verify(mockedLogRepository.receive(any)).called(2);

            expect(expectedMessages.length, 0);
          },
        );

        test(
          ': returns bool',
          () {
            const expectedResult = true;

            bool testFunction() => expectedResult;

            final expectedMessages = ['start', 'end => $expectedResult'];

            when(mockedLogRepository.receive(any)).thenAnswer((realInvocation) {
              expect(realInvocation.positionalArguments.length, 1);

              final arg1 = realInvocation.positionalArguments[0];
              expect(arg1, isA<LogEntity>());
              expect(arg1.message, expectedMessages.removeAt(0));
            });

            final result = logService.functionLog(testFunction);

            verify(mockedLogRepository.receive(any)).called(2);

            expect(result, expectedResult);

            expect(expectedMessages.length, 0);
          },
        );
      });

      test(
        ': with args',
        () {
          const testArg1 = 'test arg1';
          const testArgMap = {'testArg1': testArg1};

          void testFunction(String arg1) {}

          final expectedMessages = ['start :: $testArgMap', 'end'];

          when(mockedLogRepository.receive(any)).thenAnswer((realInvocation) {
            expect(realInvocation.positionalArguments.length, 1);

            final arg1 = realInvocation.positionalArguments[0];
            expect(arg1, isA<LogEntity>());
            expect(arg1.message, expectedMessages.removeAt(0));
          });

          logService.functionLog(
            arguments: testArgMap,
            () => testFunction(testArg1),
          );

          verify(mockedLogRepository.receive(any)).called(2);

          expect(expectedMessages.length, 0);
        },
      );
    });

    group(': async function', () {
      test(
        ': no await',
        () {
          Future<void> testFunction() async {}

          final expectedMessages = ['start', 'end => Future'];

          when(mockedLogRepository.receive(any)).thenAnswer((realInvocation) {
            expect(realInvocation.positionalArguments.length, 1);

            final arg1 = realInvocation.positionalArguments[0];
            expect(arg1, isA<LogEntity>());
            expect(arg1.message, expectedMessages.removeAt(0));
          });

          final resultFuture = logService.functionLog(testFunction);

          expect(resultFuture, isA<Future>());

          verify(mockedLogRepository.receive(any)).called(1);

          expect(expectedMessages.length, 1);
        },
      );

      group(': await', () {
        test(
          ': no returns',
          () async {
            Future<void> testFunction() async {}

            final expectedMessages = ['start', 'end => Future'];

            when(mockedLogRepository.receive(any)).thenAnswer((realInvocation) {
              expect(realInvocation.positionalArguments.length, 1);

              final arg1 = realInvocation.positionalArguments[0];
              expect(arg1, isA<LogEntity>());
              expect(arg1.message, expectedMessages.removeAt(0));
            });

            await logService.functionLog(testFunction);

            verify(mockedLogRepository.receive(any)).called(2);

            expect(expectedMessages.length, 0);
          },
        );

        test(
          ': returns bool',
          () async {
            const expectedResult = true;

            Future<bool> testFunction() async => expectedResult;

            final expectedMessages = [
              'start',
              'end => Future => $expectedResult',
            ];

            when(mockedLogRepository.receive(any)).thenAnswer((realInvocation) {
              expect(realInvocation.positionalArguments.length, 1);

              final arg1 = realInvocation.positionalArguments[0];
              expect(arg1, isA<LogEntity>());
              expect(arg1.message, expectedMessages.removeAt(0));
            });

            final result = await logService.functionLog(testFunction);

            verify(mockedLogRepository.receive(any)).called(2);

            expect(result, expectedResult);

            expect(expectedMessages.length, 0);
          },
        );
      });
    });

    test(
      'Exception occurred',
      () {
        final thrownException = Exception('test exception');
        void throwsException() => throw thrownException;

        final expectedMessages = ['start', 'Caught'];
        final expectedExceptions = [null, thrownException];

        when(mockedLogRepository.receive(any)).thenAnswer((realInvocation) {
          expect(realInvocation.positionalArguments.length, 1);

          final arg1 = realInvocation.positionalArguments[0];
          expect(arg1, isA<LogEntity>());
          expect(arg1.message, expectedMessages.removeAt(0));
          expect(arg1.error, expectedExceptions.removeAt(0));
        });

        expect(
          () => logService.functionLog(throwsException),
          throwsA((e) {
            expect(e, thrownException);
            return true;
          }),
        );

        verify(mockedLogRepository.receive(any)).called(2);

        expect(expectedMessages.length, 0);
      },
    );

    group('Under debug', () {
      LogService.reset();
      final logService = LogService(
        Level.trace,
        logRepository: mockedLogRepository,
      );

      test(
        'child functions become debug under debug function',
        () {
          void verboseFunction() => logService.functionLog(
                () {},
                level: Level.verbose,
              );
          void debugFunction() => logService.functionLog(
                () {
                  verboseFunction();
                },
                level: Level.debug,
              );

          debugFunction();
          verboseFunction();

          verify(mockedLogRepository.receive(any)).called(4);
        },
      );
    });
  });
}
