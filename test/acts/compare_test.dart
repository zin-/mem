import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:test/test.dart';

const _name = 'Act test: compare';

void main() => group(
      _name,
      () {
        group(
          ': compare',
          () {
            const name = 'name';
            const act = 'act';

            final acts = [
              {name: 'null', act: null},
              {name: 'active 0', act: Act.by(0, DateAndTime(0))},
              {name: 'active 1', act: Act.by(1, DateAndTime(1))},
              {name: 'active 2', act: Act.by(2, DateAndTime(2))},
              {
                name: 'finished 0',
                act: Act.by(3, DateAndTime(0), endWhen: DateAndTime(0))
              },
              {
                name: 'finished 1',
                act: Act.by(4, DateAndTime(1), endWhen: DateAndTime(1))
              },
              {
                name: 'finished 2',
                act: Act.by(5, DateAndTime(2), endWhen: DateAndTime(2))
              },
            ];
            final expectedList = [
              // null
              0, 1, 1, 1, -1, -1, -1,
              // active 0
              -1, 0, 1, 1, -1, -1, -1,
              // active 1
              -1, -1, 0, 1, -1, -1, -1,
              // active 2
              -1, -1, -1, 0, -1, -1, -1,
              // finished 0
              1, 1, 1, 1, 0, -1, -1,
              // finished 1
              1, 1, 1, 1, 1, 0, -1,
              // finished 2
              1, 1, 1, 1, 1, 1, 0,
            ];
            final onlyActiveExpectedList = [
              // null
              0, 1, 1, 1, 0, 0, 0,
              // active 0
              -1, 0, 1, 1, -1, -1, -1,
              // active 1
              -1, -1, 0, 1, -1, -1, -1,
              // active 2
              -1, -1, -1, 0, -1, -1, -1,
              // finished 0
              0, 1, 1, 1, 0, 0, 0,
              // finished 1
              0, 1, 1, 1, 0, 0, 0,
              // finished 2
              0, 1, 1, 1, 0, 0, 0,
            ];

            for (final onlyActive in [false, true]) {
              for (final a in acts) {
                for (final b in acts) {
                  test(
                    'onlyActive: $onlyActive, ${a[name]}, ${b[name]}.',
                    () {
                      final result = Act.compare(
                        (a[act] as Act?),
                        (b[act] as Act?),
                        onlyActive: onlyActive,
                      );

                      expect(
                        result,
                        onlyActive
                            ? onlyActiveExpectedList.removeAt(0)
                            : expectedList.removeAt(0),
                      );
                    },
                  );
                }
              }
            }
          },
        );
      },
    );
