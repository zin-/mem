import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/act.dart';
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
      },
    );
