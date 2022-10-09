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

          logService.log(message, level: level);

          verify(mockedLogRepository.receive(any)).called(1);
        },
        tags: TestSize.small,
      );

      test(
        ': message level error',
        () {
          const level = Level.error;
          const message = 'test message';

          logService.log(message, level: level);

          verify(mockedLogRepository.receive(any)).called(1);
        },
        tags: TestSize.small,
      );

      test(
        ': message level warning',
        () {
          const level = Level.warning;
          const message = 'test message';

          logService.log(message, level: level);

          verifyNever(mockedLogRepository.receive(any));
        },
        tags: TestSize.small,
      );
    });
  });
}
