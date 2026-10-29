import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/count_target.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:test/test.dart';

void main() {
  group('CountTarget', () {
    final mem = Mem(1, 'm', null, null);
    final acts = [
      Act.by(
        1,
        startWhen: DateAndTime(2026, 10, 30, 9),
        endWhen: DateAndTime(2026, 10, 30, 10),
      ),
      Act.by(
        1,
        startWhen: DateAndTime(2026, 10, 30, 11),
        endWhen: DateAndTime(2026, 10, 30, 12),
      ),
    ];

    Target target({
      TargetUnit unit = TargetUnit.count,
      int value = 3,
    }) =>
        Target(
          memId: mem.id,
          targetType: TargetType.equalTo,
          targetUnit: unit,
          value: value,
          period: Period.aDay,
        );

    test('returns the count of the given acts and the target value', () {
      final countTarget = CountTarget.of(mem, target(), acts);

      expect(countTarget?.mem, same(mem));
      expect(countTarget?.count, acts.length);
      expect(countTarget?.targetValue, 3);
      expect(CountTarget.of(mem, target(), const [])?.count, 0);
    });

    test('is absent when there is no count target with a positive value', () {
      expect(CountTarget.of(mem, null, acts), isNull);
      expect(
        CountTarget.of(mem, target(unit: TargetUnit.time), acts),
        isNull,
      );
      expect(CountTarget.of(mem, target(value: 0), acts), isNull);
    });
  });
}
