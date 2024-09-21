import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';

void main() {
  const memId = 0;
  final now = DateAndTime.now();
  final addOne = now.add(const Duration(microseconds: 1));

  final notActives = [
    null,
    Act(memId, DateAndTimePeriod(start: now, end: now)),
  ];

  group(
    'activeCompare',
    () {
      for (var a in notActives) {
        for (var b in notActives) {
          test(
            'a is ${a?.isActive} with b is ${b?.isActive}',
            () {
              final result = Act.activeCompare(a, b);

              expect(result, 0);
            },
          );
        }
      }

      group(
        'active with',
        () {
          for (var notActive in notActives) {
            test(
              ' ${notActive?.isActive}',
              () {
                final a = Act(memId, DateAndTimePeriod(start: now));

                final result = Act.activeCompare(a, notActive);

                expect(result, -1);
              },
            );
          }
        },
      );

      group(
        'active with active',
        () {
          test(
            'same start',
            () {
              final a = Act(memId, DateAndTimePeriod(start: now));
              final b = Act(memId, DateAndTimePeriod(start: now));

              final result = Act.activeCompare(a, b);

              expect(result, 0);
            },
          );
          test(
            'different start',
            () {
              final a = Act(memId, DateAndTimePeriod(start: now));
              final b = Act(memId, DateAndTimePeriod(start: addOne));

              final result = Act.activeCompare(a, b);

              expect(result, -1);
            },
          );
        },
      );
    },
  );
}
