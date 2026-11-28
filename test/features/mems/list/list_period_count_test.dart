import '../../../entity_factories.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/period.dart';
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

  group('ListPeriodWindows', () {
    const startOfDay = TimeOfDay(hour: 5, minute: 0);
    final now = DateTime(2026, 11, 9, 10);
    final createdAt = DateTime(2026, 11, 1);

    Target countTarget({
      required int memId,
      required Period period,
      TargetUnit unit = TargetUnit.count,
    }) =>
        Target(
          memId: memId,
          targetType: TargetType.equalTo,
          targetUnit: unit,
          value: 2,
          period: period,
        );

    test('skips a mem when the period is null', () {
      final weekly = savedMem(
        id: 1,
        name: 'weekly',
        createdAt: createdAt,
        updatedAt: createdAt,
        target: countTarget(memId: 1, period: Period.aWeek),
      );

      final windows = ListPeriodWindows.of(
        mems: [weekly],
        startOfDay: startOfDay,
        now: now,
      );

      expect(windows.groups, isEmpty);
    });

    test('groups count targets that share a window and omits other targets',
        () {
      final first = savedMem(
        id: 1,
        name: 'first',
        createdAt: createdAt,
        updatedAt: createdAt,
        target: countTarget(memId: 1, period: Period.aDay),
      );
      final second = savedMem(
        id: 2,
        name: 'second',
        createdAt: createdAt,
        updatedAt: createdAt,
        target: countTarget(memId: 2, period: Period.aDay),
      );
      final time = savedMem(
        id: 3,
        name: 'time',
        createdAt: createdAt,
        updatedAt: createdAt,
        target: countTarget(
          memId: 3,
          period: Period.aDay,
          unit: TargetUnit.time,
        ),
      );

      final windows = ListPeriodWindows.of(
        mems: [first, second, time],
        startOfDay: startOfDay,
        now: now,
      );

      expect(windows.groups, hasLength(1));
      expect(windows.groups.single.memIds, [1, 2]);
    });
  });
}
