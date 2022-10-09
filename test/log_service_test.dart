import 'package:flutter_test/flutter_test.dart';
import 'package:mem/repositories/log_repository.dart';
import 'package:mem/services/log_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '_helpers.dart';

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
    final logService = LogService();

    expect(logService, isA<LogService>());
  });

  group('log', () {
    group(': call when message level is greater than log level', () {
      final logService = LogService(
        Level.error,
        mockedLogRepository,
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
        tags: TestSize.small,
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
        tags: TestSize.small,
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
        tags: TestSize.small,
      );
    });
  });
}
