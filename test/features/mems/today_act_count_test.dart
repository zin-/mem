import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/today_act_count.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

void main() {
  group('TodayActCount', () {
    Target dailyCount({int value = 4}) => Target(
          memId: 0,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: value,
          period: Period.aDay,
        );

    test('of keeps a daily count of two or more', () {
      final count = TodayActCount.of(dailyCount(), 2);

      expect(count?.value, 2);
      expect(count?.target.value, 4);
    });

    test('of is null when the mem is not a daily count of two or more', () {
      expect(TodayActCount.of(dailyCount(value: 1), 1), isNull);
      expect(
        TodayActCount.of(
          Target(
            memId: 0,
            targetType: TargetType.equalTo,
            targetUnit: TargetUnit.count,
            value: 2,
            period: Period.aWeek,
          ),
          1,
        ),
        isNull,
      );
      expect(TodayActCount.of(null, 1), isNull);
    });

    test('period is the logical day of now', () {
      const startOfDay = TimeOfDay(hour: 5, minute: 0);
      final now = DateTime(2026, 11, 9, 10);
      final period = TodayActCount.period(now, startOfDay);

      expect(period.start, DateAndTime(2026, 11, 9, 5, 0));
      expect(period.end, DateAndTime(2026, 11, 10, 5, 0));
    });
  });
}
