import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_repository_v2.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/logger/logger_wrapper_v2.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'logger_service_test.mocks.dart';

@GenerateMocks([
  LoggerWrapperV2,
])
void main() {
  final mockedLoggerWrapper = MockLoggerWrapperV2();
  LogRepositoryV2(mockedLoggerWrapper);

  test(': target is value.', () {
    const target = 1;

    when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);

    final result = i(target);

    expect(result, target);

    verify(mockedLoggerWrapper.log(
      Level.info,
      target.toString(),
      null,
      null,
    )).called(1);
  });
}
