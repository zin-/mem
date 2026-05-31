import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

const _name = 'Act test';

void main() => group(
      _name,
      () {
        group('ActiveAct', () {
          test('New.', () {
            final act = Act.by(0, startWhen: DateAndTime(0));

            expect(act, isA<ActiveAct>());
            expect(act.isActive, isTrue);
            expect(act.isFinished, isFalse);
          });

          test('Finish.', () {
            final activeAct = Act.by(0, startWhen: DateAndTime(0));

            final finishedAct = activeAct.finish(DateAndTime(1));

            expect(finishedAct, isA<FinishedAct>());
          });
          test('Start.', () {
            final activeAct = Act.by(0, startWhen: DateAndTime(0));

            expect(
              () => activeAct.start(DateAndTime(1)),
              throwsA(isA<StateError>()),
            );
          });
        });

        group('FinishedAct', () {
          test('New.', () {
            final act = Act.by(
              0,
              startWhen: DateAndTime(0),
              endWhen: DateAndTime(0),
            );

            expect(act, isA<FinishedAct>());
            expect(act.isActive, isFalse);
            expect(act.isFinished, isTrue);
          });

          test('Finish.', () {
            final finishedAct = Act.by(
              0,
              startWhen: DateAndTime(0),
              endWhen: DateAndTime(1),
            );

            expect(
              () => finishedAct.finish(DateAndTime(1)),
              throwsA(isA<StateError>()),
            );
          });
          test('Start.', () {
            final finishedAct = Act.by(
              0,
              startWhen: DateAndTime(0),
              endWhen: DateAndTime(1),
            );

            expect(
              () => finishedAct.start(DateAndTime(1)),
              throwsA(isA<StateError>()),
            );
          });
        });

        group('PausedAct', () {
          test('New.', () {
            final act = Act.by(0, pausedAt: DateAndTime(0));

            expect(act, isA<PausedAct>());
            expect(act.isActive, isFalse);
            expect(act.isFinished, isFalse);
          });

          test('Finish.', () {
            final pausedAct = Act.by(0, pausedAt: DateAndTime(0));

            final finishedAct = pausedAct.finish(DateAndTime(1));

            expect(finishedAct, isA<FinishedAct>());
          });
          test('Start.', () {
            final pausedAct = Act.by(0, pausedAt: DateAndTime(0));

            final finishedAct = pausedAct.start(DateAndTime(1));

            expect(finishedAct, isA<ActiveAct>());
          });
        });

        test('Throw.', () {
          expect(
            () => Act.by(0),
            throwsA(isA<ArgumentError>()),
          );
        });

        group('ActKind', () {
          test('actKindFromStored maps known values', () {
            expect(actKindFromStored('finished'), ActKind.finished);
            expect(actKindFromStored('skipped'), ActKind.skipped);
            expect(actKindFromStored(null), isNull);
            expect(actKindFromStored(1), isNull);
            expect(actKindFromStored('unknown'), isNull);
          });

          test('skipped finished act exposes isSkipped and isScheduleAnchor', () {
            final skipped = Act.by(
              0,
              startWhen: DateAndTime(2024, 1, 1),
              endWhen: DateAndTime(2024, 1, 1, 1),
              completionKind: ActKind.skipped,
            );

            expect(skipped.isSkipped, isTrue);
            expect(skipped.isScheduleAnchor, isTrue);
            expect(skipped.isFinished, isTrue);
          });

          test('completionKindFromRow preserves null actKind from row', () {
            final legacy = Act.by(
              0,
              startWhen: DateAndTime(2024, 1, 1),
              endWhen: DateAndTime(2024, 1, 1, 1),
              completionKindFromRow: true,
            );

            expect(legacy.actKind, isNull);
          });
        });

        group('ActiveAct skip', () {
          test('skip produces skipped FinishedAct', () {
            final active = Act.by(0, startWhen: DateAndTime(2024, 1, 1, 9));
            final skipped = (active as ActiveAct).skip(DateAndTime(2024, 1, 1, 10));

            expect(skipped.actKind, ActKind.skipped);
            expect(skipped.period?.start?.hour, 9);
            expect(skipped.period?.end?.hour, 10);
          });
        });
      },
    );
