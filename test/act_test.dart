import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

const _name = 'Act test';

void main() => group(
      _name,
      () {
        group(
          ': ActiveAct',
          () {
            test(
              ': new.',
              () {
                final act = Act.by(0, startWhen: DateAndTime(0));

                expect(act, isA<ActiveAct>());
                expect(act.isActive, isTrue);
                expect(act.isFinished, isFalse);
              },
            );

            test(
              ': finish.',
              () {
                final activeAct = Act.by(0, startWhen: DateAndTime(0));

                final finishedAct = activeAct.finish(DateAndTime(1));

                expect(finishedAct, isA<FinishedAct>());
              },
            );
            test(
              ': start.',
              () {
                final activeAct = Act.by(0, startWhen: DateAndTime(0));

                expect(
                  () => activeAct.start(DateAndTime(1)),
                  throwsA(isA<StateError>()),
                );
              },
            );
          },
        );

        group(
          ': FinishedAct',
          () {
            test(
              ': new.',
              () {
                final act = Act.by(
                  0,
                  startWhen: DateAndTime(0),
                  endWhen: DateAndTime(0),
                );

                expect(act, isA<FinishedAct>());
                expect(act.isActive, isFalse);
                expect(act.isFinished, isTrue);
              },
            );

            test(
              ': finish.',
              () {
                final finishedAct = Act.by(
                  0,
                  startWhen: DateAndTime(0),
                  endWhen: DateAndTime(1),
                );

                expect(
                  () => finishedAct.finish(DateAndTime(1)),
                  throwsA(isA<StateError>()),
                );
              },
            );
            test(
              ': start.',
              () {
                final finishedAct = Act.by(
                  0,
                  startWhen: DateAndTime(0),
                  endWhen: DateAndTime(1),
                );

                expect(
                  () => finishedAct.start(DateAndTime(1)),
                  throwsA(isA<StateError>()),
                );
              },
            );
          },
        );

        group(
          ': PausedAct',
          () {
            test(
              ': new.',
              () {
                final act = Act.by(0, startWhen: null);

                expect(act, isA<PausedAct>());
                expect(act.isActive, isFalse);
                expect(act.isFinished, isFalse);
              },
            );

            test(
              ': finish.',
              () {
                final pausedAct = Act.by(0, startWhen: null);

                final finishedAct = pausedAct.finish(DateAndTime(1));

                expect(finishedAct, isA<FinishedAct>());
              },
            );
            test(
              ': start.',
              () {
                final pausedAct = Act.by(0, startWhen: null);

                final finishedAct = pausedAct.start(DateAndTime(1));

                expect(finishedAct, isA<ActiveAct>());
              },
            );
          },
        );
      },
    );
