import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/list/list_period_count.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

void main() {
  group('ListPeriodCount', () {
    const startOfDay = TimeOfDay(hour: 5, minute: 0);
    final now = DateTime(2026, 11, 9, 10);

    Target countTarget({
      required Period period,
      int value = 2,
    }) =>
        Target(
          memId: 1,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: value,
          period: period,
        );

    test('of is null when the target is not a positive count', () {
      expect(
        ListPeriodCount.of(target: null, value: 1),
        isNull,
      );
      expect(
        ListPeriodCount.of(
          target: countTarget(period: Period.aDay, value: 0),
          value: 1,
        ),
        isNull,
      );
    });

    test('of keeps a positive count target value', () {
      expect(
        ListPeriodCount.of(
          target: countTarget(period: Period.aDay),
          value: 3,
        )?.value,
        3,
      );
    });

    test('period for a day is the logical day of now', () {
      final period = ListPeriodCount.period(
        target: countTarget(period: Period.aDay),
        latestAct: null,
        startOfDay: startOfDay,
        now: now,
      );

      expect(period?.start, DateAndTime(2026, 11, 9, 5, 0));
      expect(period?.end, DateAndTime(2026, 11, 10, 5, 0));
    });

    test('period for a week ends on startOfToday', () {
      final latestAct = Act.by(
        1,
        startWhen: DateAndTime(2026, 11, 8, 12),
        endWhen: DateAndTime(2026, 11, 8, 13),
      );
      final period = ListPeriodCount.period(
        target: countTarget(period: Period.aWeek),
        latestAct: latestAct,
        startOfDay: startOfDay,
        now: now,
      );

      expect(period?.start, DateAndTime(2026, 11, 3, 5, 0));
      expect(period?.end, DateAndTime(2026, 11, 10, 5, 0));
    });
  });
}
