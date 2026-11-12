import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/notifications/mem_notifications.dart';

void main() {
  const startOfDay = TimeOfDay(hour: 0, minute: 0);
  const dailyTargetCount = 4;
  const belowTargetCount = 1;
  const intervalSeconds = 2 * 60 * 60;

  final startOfToday = DateTime(2026, 11, 9);
  final todayAtNine = DateTime(2026, 11, 9, 9);
  final tomorrowAtNine = DateTime(2026, 11, 10, 9);
  final noon = DateTime(2026, 11, 9, 12);

  final dailyAtNine = [
    MemNotification.by(
      1,
      MemNotificationType.repeat,
      9 * 60 * 60,
      'repeat at 09:00',
    ),
  ];

  Target countTarget({
    int value = dailyTargetCount,
    int? secondsAfterLastAct,
    TargetUnit unit = TargetUnit.count,
    Period period = Period.aDay,
  }) =>
      Target(
        memId: 1,
        targetType: TargetType.equalTo,
        targetUnit: unit,
        value: value,
        period: period,
        secondsAfterLastAct: secondsAfterLastAct,
      );

  Act finished(DateAndTime start, DateAndTime end) => Act.by(
        1,
        startWhen: start,
        endWhen: end,
      );

  Mem memWith(Act latest, {Act? anchor}) => Mem(
        1,
        'm',
        null,
        null,
        latestAct: latest,
        scheduleAnchorAct: anchor ?? latest,
      );

  DateTime? listAt(
    Act latest, {
    required Target target,
    required int todayCount,
    Act? anchor,
    List<MemNotification>? notifications,
  }) =>
      memWith(latest, anchor: anchor)
          .memListAt(
            startOfToday,
            notifications ?? dailyAtNine,
            target: target,
            periodCount: todayCount,
          )
          ?.at;

  DateTime? fireAt(
    Act latest,
    DateTime now, {
    required Target target,
    required int todayCount,
    Act? anchor,
    List<MemNotification>? notifications,
  }) =>
      MemNotifications.nextRepeatNotifyAt(
        notifications ?? dailyAtNine,
        startOfDay,
        latest,
        anchor ?? latest,
        now,
        target: target,
        todayCount: todayCount,
      );

  final doneToday = finished(
    DateAndTime(2026, 11, 9, 7),
    DateAndTime(2026, 11, 9, 7, 30),
  );
  final endedAtTen = finished(
    DateAndTime(2026, 11, 9, 9),
    DateAndTime(2026, 11, 9, 10),
  );
  final endedAtElevenPm = finished(
    DateAndTime(2026, 11, 9, 22),
    DateAndTime(2026, 11, 9, 23),
  );
  final repeatAtQuarterToMidnight = [
    MemNotification.by(
      1,
      MemNotificationType.repeat,
      23 * 60 * 60 + 45 * 60,
      'repeat at 23:45',
    ),
  ];
  final todayAtQuarterToMidnight = DateTime(2026, 11, 9, 23, 45);

  group('daily count stays on its day', () {
    final belowTarget = countTarget();

    test('list stays on today while the count is below the target', () {
      expect(
        listAt(doneToday, target: belowTarget, todayCount: belowTargetCount),
        todayAtNine,
      );
    });

    test('repeat stays on today when that fixed time is still ahead', () {
      expect(
        fireAt(
          doneToday,
          DateTime(2026, 11, 9, 8),
          target: belowTarget,
          todayCount: belowTargetCount,
        ),
        todayAtNine,
      );
    });

    test('repeat uses the next fixed time when today\'s time is past', () {
      expect(
        fireAt(
          doneToday,
          DateTime(2026, 11, 9, 10),
          target: belowTarget,
          todayCount: belowTargetCount,
        ),
        tomorrowAtNine,
      );
    });

    test('list and repeat move to the next day once the count is reached', () {
      final reached = countTarget(secondsAfterLastAct: intervalSeconds);

      expect(
        listAt(endedAtTen, target: reached, todayCount: dailyTargetCount),
        tomorrowAtNine,
      );
      expect(
        fireAt(
          endedAtTen,
          DateTime(2026, 11, 9, 10, 30),
          target: reached,
          todayCount: dailyTargetCount,
        ),
        tomorrowAtNine,
      );
    });

    test('list and repeat use the interval on the same logical day', () {
      final withInterval = countTarget(secondsAfterLastAct: intervalSeconds);

      expect(
        listAt(
          endedAtTen,
          target: withInterval,
          todayCount: belowTargetCount,
        ),
        noon,
      );
      expect(
        fireAt(
          endedAtTen,
          DateTime(2026, 11, 9, 10, 30),
          target: withInterval,
          todayCount: belowTargetCount,
        ),
        noon,
      );
    });

    test('an interval on the next logical day keeps today\'s fixed time', () {
      final withInterval = countTarget(secondsAfterLastAct: intervalSeconds);

      expect(
        listAt(
          endedAtElevenPm,
          target: withInterval,
          todayCount: belowTargetCount,
          notifications: repeatAtQuarterToMidnight,
        ),
        todayAtQuarterToMidnight,
      );
      expect(
        fireAt(
          endedAtElevenPm,
          DateTime(2026, 11, 9, 23, 30),
          target: withInterval,
          todayCount: belowTargetCount,
          notifications: repeatAtQuarterToMidnight,
        ),
        todayAtQuarterToMidnight,
      );
    });

    test('a target that is not a daily count keeps the current time', () {
      final onceADay = countTarget(value: 1);

      expect(
        listAt(doneToday, target: onceADay, todayCount: belowTargetCount),
        tomorrowAtNine,
      );
      expect(
        fireAt(
          doneToday,
          DateTime(2026, 11, 9, 8),
          target: onceADay,
          todayCount: belowTargetCount,
        ),
        tomorrowAtNine,
      );
    });

    test('a skipped latest act keeps the current time', () {
      final anchor = finished(
        DateAndTime(2026, 11, 8, 17),
        DateAndTime(2026, 11, 8, 18),
      );
      final skipped = Act.by(
        1,
        startWhen: DateAndTime(2026, 11, 9, 12),
        endWhen: DateAndTime(2026, 11, 9, 12),
        completionKind: ActKind.skipped,
      );

      expect(
        listAt(
          skipped,
          anchor: anchor,
          target: belowTarget,
          todayCount: belowTargetCount,
        ),
        tomorrowAtNine,
      );
      expect(
        fireAt(
          skipped,
          DateTime(2026, 11, 9, 8),
          anchor: anchor,
          target: belowTarget,
          todayCount: belowTargetCount,
        ),
        todayAtNine,
      );
    });
  });

  group('repeat notify at', () {
    test('is null while an act is still running', () {
      final running = Act.by(
        1,
        startWhen: DateAndTime(2026, 11, 9, 8),
      );

      expect(
        fireAt(
          running,
          DateTime(2026, 11, 9, 8, 30),
          target: countTarget(),
          todayCount: belowTargetCount,
        ),
        isNull,
      );
    });

    test('is null when there is no repeat notification', () {
      expect(
        MemNotifications.nextRepeatNotifyAt(
          [],
          startOfDay,
          doneToday,
          doneToday,
          DateTime(2026, 11, 9, 8),
        ),
        isNull,
      );
      expect(
        MemNotifications.nextRepeatNotifyAt(
          [
            MemNotification.by(
              1,
              MemNotificationType.afterActStarted,
              60,
              null,
            ),
          ],
          startOfDay,
          doneToday,
          doneToday,
          DateTime(2026, 11, 9, 8),
        ),
        isNull,
      );
    });

    test(
        'uses start of day and the next selected weekday when there is no fixed time',
        () {
      const dayStart = TimeOfDay(hour: 5, minute: 30);
      final now = DateTime(2026, 11, 9, 10);
      final dayAfterAnchor = DateTime(2026, 11, 10);
      final wantedWeekday = dayAfterAnchor.weekday % DateTime.daysPerWeek + 1;

      expect(
        MemNotifications.nextRepeatNotifyAt(
          [
            MemNotification.by(
              1,
              MemNotificationType.repeatByDayOfWeek,
              wantedWeekday,
              'weekday',
            ),
          ],
          dayStart,
          doneToday,
          doneToday,
          now,
        ),
        DateTime(2026, 11, 11, dayStart.hour, dayStart.minute),
      );
    });
  });
}
