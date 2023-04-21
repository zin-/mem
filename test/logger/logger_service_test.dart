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

  setUp(() {
    reset(mockedLoggerWrapper);
  });

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

  group(': target is Future', () {
    test(': sync.', () {
      final target = Future.value(1);

      when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);

      final result = i(target);

      expect(result, target);

      verifyNever(mockedLoggerWrapper.log(any, any, any, any));
    });
    test(': await.', () async {
      final target = Future.value(2);

      when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);

      final result = await i(target);

      expect(result, 2);

      verify(mockedLoggerWrapper.log(
        Level.info,
        '[future] : 2',
        any,
        any,
      )).called(1);
    });
  });

  group(': target is Function', () {
    test(': simple.', () {
      int target(int a, int b) => i(
            () => a + b,
            [a, b],
          );

      when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);

      final result = target(2, 3);

      expect(result, 5);

      expect(
        verify(mockedLoggerWrapper.log(any, captureAny, any, any)).captured,
        [
          '[start] :: [2, 3]',
          '[ end ] => 5',
        ],
      );
    });
    test(': cascade.', () {
      int childFuncInfo(int a, int b) => i(
            () => a * b,
            {a, b},
          );
      int childFuncVerbose(int a, int b) => v(
            () => a + b,
            {a, b},
          );

      int target(int a, int b) => d(
            () {
              final c = childFuncInfo(a, b);
              final d = childFuncVerbose(a, b);

              return c - d;
            },
            [a, b],
          );

      when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);

      final result = target(4, 5);
      childFuncVerbose(6, 7);

      expect(result, 11);

      expect(
        verify(mockedLoggerWrapper.log(captureAny, captureAny, any, any))
            .captured,
        [
          Level.debug,
          '[start] :: [4, 5]',
          Level.info,
          '[DEBUG][start] :: {4, 5}',
          Level.info,
          '[DEBUG][ end ] => 20',
          Level.verbose,
          '[DEBUG][start] :: {4, 5}',
          Level.verbose,
          '[DEBUG][ end ] => 9',
          Level.debug,
          '[ end ] => 11',
        ],
      );
    });

    test(': result type is void.', () {
      void target(int a, int b) => i(
            () {
              a + b;
            },
            [a, b],
          );

      when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);

      target(2, 3);

      expect(
        verify(mockedLoggerWrapper.log(any, captureAny, any, any)).captured,
        [
          '[start] :: [2, 3]',
          '[ end ] => void',
        ],
      );
    });
    test(': result type is Future.', () async {
      Future<int> target(int a, int b) => i(
            () => Future(() => a + b),
            [a, b],
          );

      when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);

      final result = await target(4, 5);

      expect(result, 9);

      expect(
        verify(mockedLoggerWrapper.log(any, captureAny, any, any)).captured,
        [
          '[start] :: [4, 5]',
          '[ end ] => [future] : 9',
        ],
      );
    });

    test(': error occurred.', () {
      const a = 8;
      const b = 9;

      final thrown = Exception('test exception :: $a, $b');
      int target(int a, int b) => i(
            () {
              throw thrown;
            },
            [a, b],
          );

      when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);

      expect(
        () => target(a, b),
        throwsA(
          (e) {
            expect(e, thrown);
            return true;
          },
        ),
      );

      expect(
        verify(mockedLoggerWrapper.log(captureAny, captureAny, captureAny, any))
            .captured,
        [
          Level.info,
          '[start] :: [8, 9]',
          null,
          Level.error,
          'Thrown is caught.',
          thrown,
        ],
      );
    });
  });
}
