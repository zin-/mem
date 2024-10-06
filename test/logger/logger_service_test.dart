import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_repository.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mockito/mockito.dart';

import '../helpers.dart';

void main() {
  final mockedLoggerWrapper = MockLoggerWrapper();
  final mockedSentryWrapper = MockSentryWrapper();

  LogRepository(
    mockedLoggerWrapper,
    mockedSentryWrapper,
  );

  final logService = LogService.initialize(
    level: Level.info,
  );

  setUp(() {
    reset(mockedLoggerWrapper);
    reset(mockedSentryWrapper);

    when(mockedSentryWrapper.captureException(any, any))
        .thenAnswer((realInvocation) => Future.value("test"));
  });

  group("valueLog", () {
    setUpAll(() {
      when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);
    });

    group(": on service level is info", () {
      for (final testCase in [
        TestCase(
          name: "verbose",
          Level.verbose,
          (Level input) =>
              verifyNever(mockedLoggerWrapper.log(any, any, any, any)),
        ),
        TestCase(
          name: "info",
          Level.info,
          (Level input) =>
              verify(mockedLoggerWrapper.log(input, any, null, null)).called(1),
        ),
      ]) {
        test(": log level is ${testCase.name}.", () {
          final level = testCase.input;
          const target = "log: test message";

          final result = logService.valueLog(level, target);

          expect(result, target);

          testCase.expected(level);
        });
      }
    });

    group(": target", () {
      test(
        ": is null.",
        () {
          const level = Level.info;
          const target = null;

          final result = logService.valueLog(level, target);

          expect(result, target);

          verify(mockedLoggerWrapper.log(
            level,
            "null",
            null,
            null,
          )).called(1);
        },
      );

      group(
        ": format",
        () {
          group(
            ": simple",
            () {
              test(
                ": List.",
                () {
                  const level = Level.info;
                  const target = [0, 1, 1];

                  final result = logService.valueLog(level, target);

                  expect(result, target);

                  expect(
                    verify(mockedLoggerWrapper.log(
                      level,
                      captureAny,
                      null,
                      null,
                    )).captured,
                    [
                      "[\n"
                          "  0,\n"
                          "  1,\n"
                          "  1,\n"
                          "]",
                    ],
                  );
                },
              );

              test(
                ": Set.",
                () {
                  const level = Level.info;
                  const target = {0, 1, 2};

                  final result = logService.valueLog(level, target);

                  expect(result, target);

                  expect(
                    verify(mockedLoggerWrapper.log(
                      level,
                      captureAny,
                      null,
                      null,
                    )).captured,
                    [
                      "{\n"
                          "  0,\n"
                          "  1,\n"
                          "  2,\n"
                          "}",
                    ],
                  );
                },
              );

              test(
                ": Map.",
                () {
                  const level = Level.info;
                  const target = {
                    "a": 0,
                    "b": 1,
                    "c": 1,
                  };

                  final result = logService.valueLog(level, target);

                  expect(result, target);

                  expect(
                    verify(mockedLoggerWrapper.log(
                      level,
                      captureAny,
                      null,
                      null,
                    )).captured,
                    [
                      "{\n"
                          "  a: 0,\n"
                          "  b: 1,\n"
                          "  c: 1,\n"
                          "}",
                    ],
                  );
                },
              );
            },
          );

          group(
            ": empty",
            () {
              test(
                ": List.",
                () {
                  const level = Level.info;
                  const target = [];

                  final result = logService.valueLog(level, target);

                  expect(result, target);

                  expect(
                    verify(mockedLoggerWrapper.log(
                      level,
                      captureAny,
                      null,
                      null,
                    )).captured,
                    [
                      "[]",
                    ],
                  );
                },
              );

              test(
                ": Set.",
                () {
                  const level = Level.info;
                  const target = <dynamic>{};

                  final result = logService.valueLog(level, target);

                  expect(result, target);

                  expect(
                    verify(mockedLoggerWrapper.log(
                      level,
                      captureAny,
                      null,
                      null,
                    )).captured,
                    [
                      "{}",
                    ],
                  );
                },
              );

              test(
                ": Map.",
                () {
                  const level = Level.info;
                  const target = {};

                  final result = logService.valueLog(level, target);

                  expect(result, target);

                  expect(
                    verify(mockedLoggerWrapper.log(
                      level,
                      captureAny,
                      null,
                      null,
                    )).captured,
                    [
                      "{}",
                    ],
                  );
                },
              );
            },
          );

          group(
            ": complicated",
            () {
              test(
                ": Map has List has Set has Map",
                () {
                  const level = Level.info;
                  const target = {
                    "a": 0,
                    "b": [
                      1,
                      {
                        1,
                        2,
                        {
                          "c": 3,
                          "d": 5,
                        },
                      },
                    ],
                  };

                  final result = logService.valueLog(level, target);

                  expect(result, target);

                  expect(
                    verify(mockedLoggerWrapper.log(
                      level,
                      captureAny,
                      null,
                      null,
                    )).captured,
                    [
                      "{\n"
                          "  a: 0,\n"
                          "  b: [\n"
                          "    1,\n"
                          "    {\n"
                          "      1,\n"
                          "      2,\n"
                          "      {\n"
                          "        c: 3,\n"
                          "        d: 5,\n"
                          "      },\n"
                          "    },\n"
                          "  ],\n"
                          "}"
                    ],
                  );
                },
              );
            },
          );
        },
      );

      group(
        ": is Future",
        () {
          test(": no await.", () {
            const level = Level.info;
            const value = "test message future";
            final target = Future.value(value);

            final result = logService.valueLog(level, target);

            expect(result, target);

            verifyNever(mockedLoggerWrapper.log(any, any, any, any));
          });

          test(": await.", () async {
            const level = Level.info;
            const value = "test message future";
            final target = Future.value(value);

            final result = await logService.valueLog(level, target);

            expect(result, value);

            expect(
              verify(mockedLoggerWrapper.log(
                level,
                "[future] >> $value",
                captureAny,
                any,
              )).captured,
              [
                null,
              ],
            );
          });

          for (final testCase in [
            TestCase(
                name: "verbose",
                Level.verbose,
                (input) =>
                    verifyNever(mockedLoggerWrapper.log(any, any, any, any))),
            TestCase(
              name: "info",
              Level.info,
              (input) =>
                  verifyNever(mockedLoggerWrapper.log(any, any, any, any)),
            ),
          ]) {
            test(
              ": on error: ${testCase.name}.",
              () async {
                final level = testCase.input;
                const errorMessage = "test message future";
                final e = Exception(errorMessage);

                verifyNever(mockedLoggerWrapper.log(any, any, any, any));
                expect(
                  () => logService.valueLog(level, Future.error(e)),
                  throwsA((thrown) {
                    expect(thrown, isA<Exception>());
                    expect(thrown.message, errorMessage);
                    return true;
                  }),
                );

                await Future(() async {
                  verify(mockedLoggerWrapper.log(
                    Level.error,
                    "[error] !!",
                    e,
                    any,
                  )).called(1);
                });
              },
            );
          }
        },
      );
    });

    group(": alias", () {
      for (final testCase in [
        TestCase(
          name: "verbose",
          verbose,
          (input) => verifyNever(mockedLoggerWrapper.log(any, any, any, any)),
        ),
        TestCase(
          name: "info",
          info,
          (input) =>
              verify(mockedLoggerWrapper.log(Level.info, "info", null, null))
                  .called(1),
        ),
        TestCase(
          name: "warn",
          warn,
          (input) =>
              verify(mockedLoggerWrapper.log(Level.warning, "warn", null, null))
                  .called(1),
        ),
        TestCase(
          name: "debug",
          // ignore: deprecated_member_use_from_same_package
          debug,
          (input) =>
              verify(mockedLoggerWrapper.log(Level.debug, "debug", null, null))
                  .called(1),
        ),
      ]) {
        test(": ${testCase.name}", () {
          final testMessage = testCase.name;

          final result = testCase.input(testMessage);

          expect(result, testMessage);

          testCase.expected(testCase.input);
        });
      }
    });
  });

  group("functionLog", () {
    group(": sync", () {
      test(": returns.", () {
        const level = Level.info;
        const arg1 = 1;
        const arg2 = 2;
        const args = [arg1, arg2];
        int sampleFunc(int a, int b) {
          return a + b;
        }

        final result = logService.functionLog(
          level,
          () => sampleFunc(arg1, arg2),
          args,
        );

        expect(result, sampleFunc(arg1, arg2));

        verify(mockedLoggerWrapper.log(
          level,
          "[start] :: [\n  $arg1,\n  $arg2,\n]",
          null,
          null,
        )).called(1);
        verify(mockedLoggerWrapper.log(
          level,
          "[end] => ${sampleFunc(arg1, arg2)}",
          null,
          null,
        )).called(1);
      });
      test(": throws.", () {
        const level = Level.info;
        const arg1 = 1;
        const arg2 = 2;
        const args = [arg1, arg2];
        final e = Exception("test exception :: functionLog: sync: throws");
        int sampleFunc(int a, int b) {
          throw e;
        }

        expect(
          () => logService.functionLog(
            level,
            () => sampleFunc(arg1, arg2),
            args,
          ),
          throwsA(isA<Exception>()),
        );

        verify(mockedLoggerWrapper.log(
          level,
          "[start] :: [\n  $arg1,\n  $arg2,\n]",
          null,
          null,
        )).called(1);
        verify(mockedLoggerWrapper.log(
          Level.error,
          "[error] !!",
          e,
          any,
        )).called(1);
      });

      group(": auto debug", () {
        group(": cascading val", () {
          test(": that is sync.", () {
            const level = Level.debug;
            const arg1 = 1;
            const arg2 = 2;
            const args = [arg1, arg2];
            int sampleFunc(int a, int b) {
              logService.valueLog(Level.verbose, "verbose log");
              return a + b;
            }

            logService.valueLog(Level.verbose, "verbose log");

            final result = logService.functionLog(
              level,
              () => sampleFunc(arg1, arg2),
              args,
            );

            expect(result, sampleFunc(arg1, arg2));

            expect(
              verify(mockedLoggerWrapper.log(
                captureAny,
                captureAny,
                null,
                null,
              )).captured,
              [
                Level.debug,
                "[start] :: [\n  $arg1,\n  $arg2,\n]",
                Level.debug,
                "** [AUTO DEBUG] ** verbose log",
                Level.debug,
                "[end] => ${sampleFunc(arg1, arg2)}",
              ],
            );
          });
          test(": that is future.", () async {
            const level = Level.debug;
            const arg1 = 1;
            const arg2 = 2;
            const args = [arg1, arg2];
            int sampleFunc(int a, int b) {
              logService.valueLog(
                  Level.verbose, Future.value("future verbose log"));
              return a + b;
            }

            logService.valueLog(Level.verbose, "verbose log - do not log");

            final result = logService.functionLog(
              level,
              () => sampleFunc(arg1, arg2),
              args,
            );

            expect(result, sampleFunc(arg1, arg2));

            await Future(() async {
              await expectLater(
                verify(mockedLoggerWrapper.log(
                  captureAny,
                  captureAny,
                  any,
                  any,
                )).captured,
                [
                  Level.debug,
                  "[start] :: [\n  $arg1,\n  $arg2,\n]",
                  Level.debug,
                  "[end] => ${sampleFunc(arg1, arg2)}",
                  Level.debug,
                  "** [AUTO DEBUG] ** [future] >> future verbose log",
                ],
              );
            });
          });
        });

        group(": cascading function", () {
          test(": that returns sync.", () {
            const level = Level.debug;
            const arg1 = 2;
            const arg2 = 3;
            const args = [arg1, arg2];

            int cascadedFunc(int c, int d) => logService.functionLog(
                  Level.verbose,
                  () {
                    return c * d;
                  },
                  {"c": c, "d": d},
                );

            int sampleFunc(int a, int b) {
              return a + cascadedFunc(a, b);
            }

            final cascadedFuncResult = cascadedFunc(arg1, arg2);
            expect(cascadedFuncResult, 6);

            final result = logService.functionLog(
              level,
              () => sampleFunc(arg1, arg2),
              args,
            );

            expect(result, sampleFunc(arg1, arg2));

            expect(
              verify(mockedLoggerWrapper.log(
                captureAny,
                captureAny,
                any,
                any,
              )).captured,
              [
                Level.debug,
                "[start] :: [\n  $arg1,\n  $arg2,\n]",
                Level.debug,
                "** [AUTO DEBUG] ** [start] :: {\n  c: 2,\n  d: 3,\n}",
                Level.debug,
                "** [AUTO DEBUG] ** [end] => 6",
                Level.debug,
                "[end] => 8",
              ],
            );
          });
          test(": that returns future.", () async {
            const level = Level.debug;
            const arg1 = 2;
            const arg2 = 3;
            const args = [arg1, arg2];

            Future<int> cascadedFunc(int c, int d) => logService.functionLog(
                  Level.verbose,
                  () async {
                    return c * d;
                  },
                  {"c": c, "d": d},
                );

            int sampleFunc(int a, int b) {
              cascadedFunc(a, b);
              return a + b;
            }

            cascadedFunc(arg1, arg2);

            final result = logService.functionLog(
              level,
              () => sampleFunc(arg1, arg2),
              args,
            );

            expect(result, sampleFunc(arg1, arg2));

            await Future(() async {
              await expectLater(
                verify(mockedLoggerWrapper.log(
                  captureAny,
                  captureAny,
                  null,
                  any,
                )).captured,
                [
                  Level.debug,
                  "[start] :: [\n  $arg1,\n  $arg2,\n]",
                  Level.debug,
                  "** [AUTO DEBUG] ** [start] :: {\n  c: 2,\n  d: 3,\n}",
                  Level.debug,
                  "[end] => 5",
                ],
              );
            });
          });
        });

        // TODO after error
      });
    });

    group(": async", () {
      test(": returns.", () async {
        const level = Level.info;
        const arg1 = 1;
        const arg2 = 2;
        const args = [arg1, arg2];
        Future<int> sampleFunc(int a, int b) async {
          return a + b;
        }

        final result = await logService.functionLog(
          level,
          () => sampleFunc(arg1, arg2),
          args,
        );

        expect(result, await sampleFunc(arg1, arg2));

        verify(mockedLoggerWrapper.log(
          level,
          "[start] :: [\n  $arg1,\n  $arg2,\n]",
          null,
          null,
        )).called(1);
        verify(mockedLoggerWrapper.log(
          level,
          "[end] => [future] >> ${await sampleFunc(arg1, arg2)}",
          any,
          any,
        )).called(1);
      });
      test(": throws.", () async {
        const level = Level.info;
        const arg1 = 1;
        const arg2 = 2;
        const args = [arg1, arg2];
        const errorMessage =
            "test exception :: functionLog: return type is future: throws";
        final e = Exception(errorMessage);
        Future<int> sampleFunc(int a, int b) async {
          throw e;
        }

        expect(
          () => logService.functionLog(
            level,
            () => sampleFunc(arg1, arg2),
            args,
          ),
          throwsA((thrown) {
            expect(thrown, isA<Exception>());
            expect(thrown.message, errorMessage);
            return true;
          }),
        );

        await Future(() async {
          await expectLater(
            verify(mockedLoggerWrapper.log(
              captureAny,
              captureAny,
              captureAny,
              any,
            )).captured,
            [
              Level.info,
              "[start] :: [\n  $arg1,\n  $arg2,\n]",
              null,
              Level.error,
              "[error] !!",
              e,
            ],
          );
        });
      });

      group(": auto debug", () {
        group(": cascading val", () {
          test(": that is future.", () async {
            const level = Level.debug;
            const arg1 = 1;
            const arg2 = 2;
            const args = [arg1, arg2];
            Future<int> sampleFunc(int a, int b) async {
              logService.valueLog(
                  Level.verbose, Future.value("future verbose log"));
              return a + b;
            }

            logService.valueLog(Level.verbose, "verbose log - do not log");

            final result = await logService.functionLog(
              level,
              () => sampleFunc(arg1, arg2),
              args,
            );

            expect(result, await sampleFunc(arg1, arg2));

            await Future(() async {
              await expectLater(
                verify(mockedLoggerWrapper.log(
                  captureAny,
                  captureAny,
                  any,
                  any,
                )).captured,
                [
                  Level.debug,
                  "[start] :: [\n  $arg1,\n  $arg2,\n]",
                  Level.debug,
                  "** [AUTO DEBUG] ** [future] >> future verbose log",
                  Level.debug,
                  "[end] => [future] >> ${await sampleFunc(arg1, arg2)}",
                ],
              );
            });
          });
        });

        group(": cascading function", () {
          test(": that returns future.", () async {
            const level = Level.debug;
            const arg1 = 2;
            const arg2 = 3;
            const args = [arg1, arg2];

            Future<int> cascadedFunc(int c, int d) => logService.functionLog(
                  Level.verbose,
                  () async {
                    return c * d;
                  },
                  {"c": c, "d": d},
                );

            Future<int> sampleFunc(int a, int b) async {
              return a + await cascadedFunc(a, b);
            }

            cascadedFunc(arg1, arg2);

            final result = await logService.functionLog(
              level,
              () => sampleFunc(arg1, arg2),
              args,
            );

            expect(result, await sampleFunc(arg1, arg2));

            await Future(() async {
              await expectLater(
                verify(mockedLoggerWrapper.log(
                  captureAny,
                  captureAny,
                  any,
                  any,
                )).captured,
                [
                  Level.debug,
                  "[start] :: [\n  $arg1,\n  $arg2,\n]",
                  Level.debug,
                  "** [AUTO DEBUG] ** [start] :: {\n  c: 2,\n  d: 3,\n}",
                  Level.debug,
                  "** [AUTO DEBUG] ** [end] => [future] >> ${await cascadedFunc(arg1, arg2)}",
                  Level.debug,
                  "[end] => [future] >> ${await sampleFunc(arg1, arg2)}",
                ],
              );
            });
          });
        });
      });
    });

    group(": alias", () {
      for (final testCase in [
        TestCase(
          name: "v",
          v,
          (input) => verifyNever(mockedLoggerWrapper.log(any, any, any, any)),
        ),
        TestCase(
          name: "i",
          i,
          (input) {
            verify(mockedLoggerWrapper.log(
                    Level.info, "[start] :: null", null, null))
                .called(1);
            verify(mockedLoggerWrapper.log(
                    Level.info, "[end] => i", null, null))
                .called(1);
          },
        ),
        TestCase(
          name: "w",
          w,
          (input) {
            verify(mockedLoggerWrapper.log(
                    Level.warning, "[start] :: null", null, null))
                .called(1);
            verify(mockedLoggerWrapper.log(
                    Level.warning, "[end] => w", null, null))
                .called(1);
          },
        ),
        TestCase(
          name: "d",
          // ignore: deprecated_member_use_from_same_package
          d,
          (input) {
            verify(mockedLoggerWrapper.log(
                    Level.debug, "[start] :: null", null, null))
                .called(1);
            verify(mockedLoggerWrapper.log(
                    Level.debug, "[end] => d", null, null))
                .called(1);
          },
        ),
      ]) {
        test(": ${testCase.name}", () {
          final testMessage = testCase.name;

          final result = testCase.input(() {
            return testMessage;
          });

          expect(result, testMessage);

          testCase.expected(testCase.input);
        });
      }
    });
  });
}
