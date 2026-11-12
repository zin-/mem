import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/mems/list/list_frame_count.dart';
import 'package:mem/features/targets/target.dart';

void main() {
  group('ListFrameCount', () {
    const startOfDay = TimeOfDay(hour: 5, minute: 0);
    final startOfToday = DateTime(2026, 11, 9, 5);

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

    ListFrameCount? frame({
      Target? target,
      int periodCount = 1,
    }) =>
        ListFrameCount.of(
          target: target,
          periodCount: periodCount,
          latestAct: null,
          startOfToday: startOfToday,
          startOfDay: startOfDay,
        );

    test('of is null when the target is not a positive count', () {
      expect(frame(target: null), isNull);
      expect(
        frame(target: countTarget(period: Period.aDay, value: 0)),
        isNull,
      );
      expect(
        frame(
          target: Target(
            memId: 1,
            targetType: TargetType.equalTo,
            targetUnit: TargetUnit.time,
            value: 60,
            period: Period.aDay,
          ),
        ),
        isNull,
      );
    });

    test('of is null when the period is neither a day nor a week', () {
      expect(frame(target: countTarget(period: Period.aMonth)), isNull);
    });
  });
}
