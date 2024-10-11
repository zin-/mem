import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:test/test.dart';

const _name = 'Act test: compare';

void main() => group(
      _name,
      () {
        group(
          ': activeCompare',
          () {
            const name = 'name';
            const act = 'act';

            final acts = [
              {name: 'null', act: null},
              {
                name: 'active 0',
                act: Act(0, DateAndTimePeriod(start: DateAndTime(0)))
              },
              {
                name: 'active 1',
                act: Act(1, DateAndTimePeriod(start: DateAndTime(1)))
              },
              {
                name: 'active 2',
                act: Act(2, DateAndTimePeriod(start: DateAndTime(2)))
              },
              {
                name: 'finished 0',
                act: Act(
                    3,
                    DateAndTimePeriod(
                        start: DateAndTime(0), end: DateAndTime(0)))
              },
            ];
            final expectedList = [
              // null
              0, 1, 1, 1, 0,
              // active 0
              -1, 0, 1, 1, -1,
              // active 1
              -1, -1, 0, 1, -1,
              // active 2
              -1, -1, -1, 0, -1,
              // finished 0
              0, 1, 1, 1, 0,
            ];

            for (final a in acts) {
              for (final b in acts) {
                test(
                  '${a[name]}, ${b[name]}.',
                  () {
                    final result = Act.activeCompare(
                      (a[act] as Act?),
                      (b[act] as Act?),
                    );

                    expect(result, expectedList.removeAt(0));
                  },
                );
              }
            }
          },
        );
      },
    );
