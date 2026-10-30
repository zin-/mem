import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/count_target.dart';
import 'package:mem/features/targets/target.dart';
import 'package:test/test.dart';

void main() {
  group('CountTarget', () {
    Target target({
      TargetUnit unit = TargetUnit.count,
      int value = 3,
    }) =>
        Target(
          memId: 1,
          targetType: TargetType.equalTo,
          targetUnit: unit,
          value: value,
          period: Period.aDay,
        );

    test('returns the given count and the target value', () {
      final countTarget = CountTarget.of(target(), 2);

      expect(countTarget?.count, 2);
      expect(countTarget?.targetValue, 3);
      expect(CountTarget.of(target(), 0)?.count, 0);
    });

    test('is absent when there is no count target with a positive value', () {
      expect(CountTarget.of(null, 2), isNull);
      expect(CountTarget.of(target(unit: TargetUnit.time), 2), isNull);
      expect(CountTarget.of(target(value: 0), 2), isNull);
    });
  });
}
