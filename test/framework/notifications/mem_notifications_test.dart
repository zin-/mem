import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/notifications/mem_notifications.dart';
import 'package:mem/framework/notifications/schedule.dart';

void main() {
  group('MemNotifications', () {
    final startOfDay = const TimeOfDay(hour: 9, minute: 0);
    final now = DateTime(2024, 10, 12, 10, 0);
    final anchorStart = DateAndTime(2024, 10, 11, 12);
    final anchorEnd = DateAndTime(2024, 10, 11, 13);

    Act skippedLatest() => Act.by(
          1,
          startWhen: anchorStart,
          endWhen: anchorEnd,
          completionKind: ActKind.skipped,
        );

    Act finishedAnchor() => Act.by(
          1,
          startWhen: anchorStart,
          endWhen: anchorEnd,
          completionKind: ActKind.finished,
        );

    test('nextRepeatNotifyAt uses now when schedule anchor is absent', () {
      final notifications = [
        MemNotification.by(1, MemNotificationType.repeat, 3600 + 120, 'r'),
      ];

      expect(
        MemNotifications.nextRepeatNotifyAt(
          notifications,
          startOfDay,
          skippedLatest(),
          null,
          now,
        ),
        DateTime(2024, 10, 13, 1, 2),
      );
    });

    test('nextRepeatNotifyAt uses schedule anchor period end', () {
      final notifications = [
        MemNotification.by(
          1,
          MemNotificationType.repeatByNDay,
          2,
          'repeat by 2 day',
        ),
      ];

      expect(
        MemNotifications.nextRepeatNotifyAt(
          notifications,
          startOfDay,
          skippedLatest(),
          finishedAnchor(),
          now,
        ),
        DateTime(2024, 10, 13, 9, 0),
      );
    });

    test('periodicScheduleOf falls back to mem.resolvedScheduleAnchor', () {
      final mem = Mem(
        1,
        'm',
        null,
        null,
        latestAct: skippedLatest(),
        scheduleAnchorAct: finishedAnchor(),
      );
      final notifications = [
        MemNotification.by(
          1,
          MemNotificationType.repeatByNDay,
          2,
          'repeat by 2 day',
        ),
      ];

      final schedule = MemNotifications.periodicScheduleOf(
        mem,
        startOfDay,
        notifications,
        skippedLatest(),
        now,
      );

      expect(schedule, isA<PeriodicSchedule>());
      expect(
        (schedule as PeriodicSchedule).startAt,
        DateTime(2024, 10, 13, 9, 0),
      );
    });
  });
}
