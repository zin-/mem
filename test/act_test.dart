import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

const _name = 'Act test';

void main() => group(
      _name,
      () {
        group(
          ': constructor',
          () {
            test(
              ': ActiveAct',
              () {
                final act = ActV2.by(0, DateAndTime(0));

                expect(act, isA<ActiveAct>());
              },
            );
            test(
              ': FinishedAct',
              () {
                final act = ActV2.by(
                  0,
                  DateAndTime(0),
                  endWhen: DateAndTime(0),
                );

                expect(act, isA<FinishedAct>());
              },
            );
          },
        );

        group(
          ': isActive',
          () {
            test(
              ': ActiveAct',
              () {
                final act = ActV2.by(0, DateAndTime(0));

                expect(act.isActive, isTrue);
              },
            );
            test(
              ': FinishedAct',
              () {
                final act = ActV2.by(
                  0,
                  DateAndTime(0),
                  endWhen: DateAndTime(0),
                );

                expect(act.isActive, isFalse);
              },
            );
          },
        );

        group(
          ': finish',
          () {
            test(
              ': ActiveAct',
              () {
                final activeAct = ActV2.by(0, DateAndTime(0));

                expect(activeAct.isActive, isTrue);

                final finishedAct = activeAct.finish(DateAndTime(1));

                expect(finishedAct.isFinished, isTrue);
              },
            );
            test(
              ': FinishedAct',
              () {
                final finishedAct = ActV2.by(
                  0,
                  DateAndTime(0),
                  endWhen: DateAndTime(1),
                );

                expect(finishedAct.isActive, isFalse);
                expect(finishedAct.isFinished, isTrue);
                expect(
                  () => finishedAct.finish(DateAndTime(1)),
                  throwsA(isA<StateError>()),
                );
              },
            );
          },
        );
      },
    );
