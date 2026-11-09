import '../../../entity_factories.dart';
import 'helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/list/filter_value.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

void main() {
  group('compareMemListEntries', () {
    final startOfToday = DateTime(2024, 10, 12, 9, 0);
    const emptyNotifications = <SavedMemNotificationEntityV1>[];

    MemEntity finishedMem({
      required int id,
      DateTime? doneAt,
      DateTime? archivedAt,
    }) =>
        savedMem(
          id: id,
          name: 'Mem $id',
          createdAt: DateTime(2024, 6, 1),
          updatedAt: DateTime(2024, 6, 1),
          doneAt: doneAt,
          archivedAt: archivedAt,
        );

    test('sorts two ActiveAct mems by start descending', () {
      final earlier = savedMem(
        id: 1,
        name: 'Earlier',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        latestAct: ActiveAct(1, DateAndTime(2024, 6, 1, 8, 0)),
      );
      final later = savedMem(
        id: 2,
        name: 'Later',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        latestAct: ActiveAct(2, DateAndTime(2024, 6, 1, 10, 0)),
      );

      expect(
        compareMemListEntries(
          later,
          earlier,
          startOfToday: startOfToday,
          savedMemNotifications: emptyNotifications,
        ),
        lessThan(0),
      );
    });

    test('sorts archived mem after non-archived', () {
      final archived = finishedMem(id: 1, archivedAt: DateTime(2024, 6, 1));
      final normal = finishedMem(id: 2);

      expect(
        compareMemListEntries(
          archived,
          normal,
          startOfToday: startOfToday,
          savedMemNotifications: emptyNotifications,
        ),
        greaterThan(0),
      );
      expect(
        compareMemListEntries(
          normal,
          archived,
          startOfToday: startOfToday,
          savedMemNotifications: emptyNotifications,
        ),
        lessThan(0),
      );
    });

    test('sorts done mem after not-done', () {
      final done = finishedMem(id: 1, doneAt: DateTime(2024, 6, 1));
      final notDone = finishedMem(id: 2);

      expect(
        compareMemListEntries(
          done,
          notDone,
          startOfToday: startOfToday,
          savedMemNotifications: emptyNotifications,
        ),
        greaterThan(0),
      );
      expect(
        compareMemListEntries(
          notDone,
          done,
          startOfToday: startOfToday,
          savedMemNotifications: emptyNotifications,
        ),
        lessThan(0),
      );
    });

    test('sorts mem with notifyAt before mem without notifyAt', () {
      final withNotify = finishedMem(id: 1);
      final withoutNotify = finishedMem(id: 2);
      final notifications = [
        savedRepeatAtHourNotification(id: 1, memId: 1, hour: 10),
      ];

      expect(
        compareMemListEntries(
          withNotify,
          withoutNotify,
          startOfToday: startOfToday,
          savedMemNotifications: notifications,
        ),
        lessThan(0),
      );
      expect(
        compareMemListEntries(
          withoutNotify,
          withNotify,
          startOfToday: startOfToday,
          savedMemNotifications: notifications,
        ),
        greaterThan(0),
      );
    });

    test('sorts mem with afterActStarted notification before mem without', () {
      final withAfter = finishedMem(id: 1);
      final withoutAfter = finishedMem(id: 2);
      final notifications = [
        savedAfterActStartedNotification(id: 1, memId: 1),
      ];

      expect(
        compareMemListEntries(
          withAfter,
          withoutAfter,
          startOfToday: startOfToday,
          savedMemNotifications: notifications,
        ),
        lessThan(0),
      );
      expect(
        compareMemListEntries(
          withoutAfter,
          withAfter,
          startOfToday: startOfToday,
          savedMemNotifications: notifications,
        ),
        greaterThan(0),
      );
    });

    test('falls back to id when sort criteria are equal', () {
      final memA = finishedMem(id: 1);
      final memB = finishedMem(id: 2);

      expect(
        compareMemListEntries(
          memA,
          memB,
          startOfToday: startOfToday,
          savedMemNotifications: emptyNotifications,
        ),
        lessThan(0),
      );
    });
  });

  group('archive and done filters', () {
    test('return to defaults when the list is left', () async {
      final active = savedMem(
        id: 1,
        name: 'active',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
      );
      final archived = savedMem(
        id: 2,
        name: 'archived',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        archivedAt: DateTime(2024, 6, 2),
      );
      final done = savedMem(
        id: 3,
        name: 'done',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        doneAt: DateTime(2024, 6, 3),
      );
      final container = memListTestContainer([active, archived, done]);
      addTearDown(container.dispose);

      final subscription = container.listen(memListProvider, (_, __) {});
      container.read(memListFilterStateProvider.notifier).updatedBy(
            const MemListFilterValue(
              showNotArchived: false,
              showArchived: true,
            ),
          );

      expect(sortedMemIds(container), [archived.id]);

      container.read(memListFilterStateProvider.notifier).updatedBy(
            const MemListFilterValue(
              showNotDone: false,
              showDone: true,
            ),
          );

      expect(sortedMemIds(container), [done.id]);

      subscription.close();
      await container.pump();

      expect(
        container.read(memListFilterStateProvider),
        const MemListFilterValue(),
      );
      expect(sortedMemIds(container), [active.id]);
    });
  });

  group('search text', () {
    test('keeps every mem when empty and keeps name matches otherwise', () {
      final alpha = savedMem(
        id: 1,
        name: 'Alpha',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
      );
      final beta = savedMem(
        id: 2,
        name: 'Beta',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
      );
      final container = memListTestContainer([alpha, beta]);
      addTearDown(container.dispose);
      final subscription = container.listen(memListProvider, (_, __) {});
      addTearDown(subscription.close);

      expect(sortedMemIds(container), [alpha.id, beta.id]);

      container.read(searchTextProvider.notifier).updatedBy('');
      expect(sortedMemIds(container), [alpha.id, beta.id]);

      container.read(searchTextProvider.notifier).updatedBy('Alp');
      expect(sortedMemIds(container), [alpha.id]);
    });
  });

  group('memListProvider', () {
    test('sorts PausedAct mems by pausedAt descending', () {
      final olderPaused = savedMem(
        id: 1,
        name: 'Older pause',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        latestAct: PausedAct(1, DateTime(2024, 6, 1, 10, 0)),
      );
      final newerPaused = savedMem(
        id: 2,
        name: 'Newer pause',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        latestAct: PausedAct(2, DateTime(2024, 6, 1, 12, 0)),
      );

      final container = memListTestContainer([olderPaused, newerPaused]);
      addTearDown(container.dispose);

      expect(sortedMemIds(container), [2, 1]);
    });

    test('keeps ActiveAct mem above PausedAct mem', () {
      final active = savedMem(
        id: 1,
        name: 'Active',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        latestAct: ActiveAct(1, DateAndTime(2024, 6, 1, 8, 0)),
      );
      final paused = savedMem(
        id: 2,
        name: 'Paused',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        latestAct: PausedAct(2, DateTime(2024, 6, 1, 12, 0)),
      );

      final container = memListTestContainer([paused, active]);
      addTearDown(container.dispose);

      expect(sortedMemIds(container), [1, 2]);
    });
  });

  group('memList section date', () {
    final startOfToday = DateTime(2024, 10, 12, 9, 0);
    final skipDay = DateAndTime(2024, 10, 12, 12, 0);

    Act skippedOnToday(int memId) => Act.by(
          memId,
          startWhen: skipDay,
          endWhen: skipDay,
          completionKind: ActKind.skipped,
        );

    MemEntity memWithSkipped({
      required int id,
      Act? scheduleAnchorAct,
    }) =>
        savedMem(
          id: id,
          name: 'Skipped today',
          createdAt: DateTime(2024, 10, 1),
          updatedAt: DateTime(2024, 10, 12),
          latestAct: skippedOnToday(id),
        ).updatedWith(
          scheduleAnchorAct: () => scheduleAnchorAct,
        );

    test(
        'skipped on today with weekly anchor is not grouped under skip day section',
        () {
      final anchor = Act.by(
        1,
        startWhen: DateAndTime(2024, 10, 5, 12, 0),
        endWhen: DateAndTime(2024, 10, 5, 12, 0),
        completionKind: ActKind.finished,
      );
      final notifications = [
        MemNotification.by(
          0,
          MemNotificationType.repeatByNDay,
          7,
          'repeat by 7 day',
        ),
      ];

      final sectionDate = memWithSkipped(id: 1, scheduleAnchorAct: anchor)
          .toDomain()
          .memListSectionDate(startOfToday, notifications);

      expect(sectionDate, isNot(DateAndTime(2024, 10, 12)));
      expect(sectionDate, DateAndTime(2024, 10, 19));
    });

    test('skip alone on today is not grouped under skip day section', () {
      final notifications = [
        MemNotification.by(
          0,
          MemNotificationType.repeatByNDay,
          2,
          'repeat by 2 day',
        ),
      ];

      final sectionDate = memWithSkipped(id: 1)
          .toDomain()
          .memListSectionDate(startOfToday, notifications);

      expect(sectionDate, isNot(DateAndTime(2024, 10, 12)));
      expect(sectionDate, DateAndTime(2024, 10, 14));
    });
  });

  group('startOfToday', () {
    const startOfDay = TimeOfDay(hour: 9, minute: 0);
    final now = DateTime(2024, 10, 12, 3, 0);

    test('before start of day returns previous calendar day at startOfDay', () {
      expect(
        DateTimeExt.startOfToday(startOfDay, now),
        DateTime(2024, 10, 11, 9, 0),
      );
    });

    test('after start of day returns same calendar day at startOfDay', () {
      expect(
        DateTimeExt.startOfToday(
          startOfDay,
          DateTime(2024, 10, 12, 15, 0),
        ),
        DateTime(2024, 10, 12, 9, 0),
      );
    });

    test('repeat at 8:00 section date uses same startOfToday as sort', () {
      final sortStartOfToday = DateTimeExt.startOfToday(startOfDay, now);
      final mem = Mem(1, 'Daily repeat', null, null);
      final notifications = [repeatAtHourMemNotification(1, 8)];

      expect(
        mem.memListSectionDate(sortStartOfToday, notifications),
        DateAndTime(2024, 10, 11),
      );
    });

    test(
        'memListProvider notifyAt order uses same startOfToday as section date',
        () {
      final sortStartOfToday = DateTimeExt.startOfToday(startOfDay, now);
      final mem = savedMem(
        id: 1,
        name: 'Daily repeat',
        createdAt: DateTime(2024, 10, 1),
        updatedAt: DateTime(2024, 10, 1),
      );
      final notification = savedRepeatAtHourNotification(
        id: 1,
        memId: 1,
        hour: 8,
      );

      final container =
          memListTestContainer([mem], notifications: [notification]);
      addTearDown(container.dispose);

      final sortedMem = container.read(memListProvider).single.toDomain();
      final notificationsForMem = [notification.value];

      expect(
        sortedMem.memListSectionDate(sortStartOfToday, notificationsForMem),
        DateAndTime(2024, 10, 11),
      );
      expect(
        sortedMem.notifyAt(sortStartOfToday, notificationsForMem, null)?.at,
        DateTime(2024, 10, 12, 8, 0),
      );
    });
  });

  group('mem list section by count', () {
    final startOfToday = DateTime(2024, 10, 12);
    const dailyTargetValue = 3;
    const belowDailyTarget = 2;
    const weeklyTargetValue = 2;
    const belowWeeklyTarget = 1;
    const notifyHour = 10;
    const earlyNotifyHour = 8;
    const laterNotifyHour = 15;
    const middayHour = 12;
    const eveningHour = 22;
    const hoursUntilToday = 3;
    const intervalHours = 4;
    const hourSeconds = Duration.secondsPerHour;

    Target countTarget({
      required int memId,
      required int value,
      required Period period,
      int? secondsAfterLastAct,
    }) =>
        Target(
          memId: memId,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: value,
          period: period,
          secondsAfterLastAct: secondsAfterLastAct,
        );

    Act finishedAt(int memId, DateTime end) {
      final ended = DateAndTime.from(end, timeOfDay: end);
      return Act.by(
        memId,
        startWhen: ended.subtract(const Duration(minutes: 30)),
        endWhen: ended,
      );
    }

    Mem memEnded(int id, DateTime end) => Mem(
          id,
          'Mem $id',
          null,
          null,
          latestAct: finishedAt(id, end),
        );

    List<MemNotification> repeatAt(int memId, int hour) => [
          MemNotification.by(
            memId,
            MemNotificationType.repeat,
            hour * hourSeconds,
            'repeat at $hour:00',
          ),
        ];

    List<MemNotification> repeatOnWednesday(int memId, int hour) => [
          ...repeatAt(memId, hour),
          MemNotification.by(
            memId,
            MemNotificationType.repeatByDayOfWeek,
            DateTime.wednesday,
            'wednesday',
          ),
        ];

    MemEntity entity({
      required int id,
      required DateTime end,
      required Target target,
    }) =>
        savedMem(
          id: id,
          name: 'Mem $id',
          createdAt: DateTime(2024, 10, 1),
          updatedAt: DateTime(2024, 10, 1),
          latestAct: finishedAt(id, end),
          target: target,
        );

    test('groups a daily count below the target on today', () {
      final section = memEnded(1, DateTime(2024, 10, 12, 9)).memListSectionDate(
        startOfToday,
        repeatAt(1, notifyHour),
        target: countTarget(
          memId: 1,
          value: dailyTargetValue,
          period: Period.aDay,
          secondsAfterLastAct: hourSeconds,
        ),
        todayCount: belowDailyTarget,
      );

      expect(section, DateAndTime(2024, 10, 12));
    });

    test(
        'groups a daily count below the target on today when the interval alone is tomorrow',
        () {
      final section =
          memEnded(1, DateTime(2024, 10, 12, 22)).memListSectionDate(
        startOfToday,
        repeatAt(1, notifyHour),
        target: countTarget(
          memId: 1,
          value: dailyTargetValue,
          period: Period.aDay,
          secondsAfterLastAct: intervalHours * hourSeconds,
        ),
        todayCount: belowDailyTarget,
      );

      expect(section, DateAndTime(2024, 10, 12));
    });

    test('groups a reached daily count by notifyAt after the last act', () {
      final section =
          memEnded(1, DateTime(2024, 10, 11, eveningHour)).memListSectionDate(
        startOfToday,
        repeatAt(1, notifyHour),
        target: countTarget(
          memId: 1,
          value: dailyTargetValue,
          period: Period.aDay,
          secondsAfterLastAct: hoursUntilToday * hourSeconds,
        ),
        todayCount: dailyTargetValue,
      );

      expect(section, DateAndTime(2024, 10, 12));
    });

    test('sorts a reached daily count with notifyAt against a mem still on today',
        () {
      final reached = entity(
        id: 1,
        end: DateTime(2024, 10, 11, eveningHour),
        target: countTarget(
          memId: 1,
          value: dailyTargetValue,
          period: Period.aDay,
          secondsAfterLastAct: hoursUntilToday * hourSeconds,
        ),
      );
      final stillToday = savedMem(
        id: 2,
        name: 'Still today',
        createdAt: DateTime(2024, 10, 1),
        updatedAt: DateTime(2024, 10, 1),
      );
      final notifications = [
        savedRepeatAtHourNotification(id: 1, memId: 1, hour: notifyHour),
        savedRepeatAtHourNotification(id: 2, memId: 2, hour: laterNotifyHour),
      ];

      expect(
        compareMemListEntries(
          reached,
          stillToday,
          startOfToday: startOfToday,
          savedMemNotifications: notifications,
          periodCountByMemId: {1: dailyTargetValue},
        ),
        lessThan(0),
      );
    });

    test('groups a weekly count below the target by notifyAt', () {
      final onToday = memEnded(1, DateTime(2024, 10, 11, laterNotifyHour))
          .memListSectionDate(
        startOfToday,
        repeatAt(1, notifyHour),
        target: countTarget(
          memId: 1,
          value: weeklyTargetValue,
          period: Period.aWeek,
        ),
        todayCount: belowWeeklyTarget,
      );
      final onALaterNotification =
          memEnded(1, DateTime(2024, 10, 12, laterNotifyHour))
              .memListSectionDate(
        startOfToday,
        repeatOnWednesday(1, notifyHour),
        target: countTarget(
          memId: 1,
          value: weeklyTargetValue,
          period: Period.aWeek,
        ),
        todayCount: belowWeeklyTarget,
      );

      expect(onToday, DateAndTime(2024, 10, 12));
      expect(onALaterNotification, DateAndTime(2024, 10, 16));
    });

    test('groups a reached weekly count by notifyAt after the last act', () {
      const startOfDay = TimeOfDay(hour: 9, minute: 0);
      final start = DateTime(2024, 10, 12, startOfDay.hour, startOfDay.minute);
      final endedBeforeStartOfDay = DateTime(2024, 10, 12, earlyNotifyHour);
      final target = countTarget(
        memId: 1,
        value: weeklyTargetValue,
        period: Period.aWeek,
      );

      expect(
        memEnded(1, endedBeforeStartOfDay).memListSectionDate(
          start,
          repeatAt(1, earlyNotifyHour),
          target: target,
          todayCount: weeklyTargetValue,
        ),
        DateAndTime(2024, 10, 12),
      );
    });

    test('sorts a reached weekly count by the notification time on that day',
        () {
      const startOfDay = TimeOfDay(hour: 9, minute: 0);
      final start = DateTime(2024, 10, 12, startOfDay.hour, startOfDay.minute);
      final end = DateTime(2024, 10, 12, earlyNotifyHour);
      Target weekly(int memId) => countTarget(
            memId: memId,
            value: weeklyTargetValue,
            period: Period.aWeek,
          );
      final early = entity(id: 1, end: end, target: weekly(1));
      final later = entity(id: 2, end: end, target: weekly(2));
      final notifications = [
        savedRepeatAtHourNotification(id: 1, memId: 1, hour: earlyNotifyHour),
        savedRepeatAtHourNotification(id: 2, memId: 2, hour: notifyHour),
      ];

      expect(
        compareMemListEntries(
          early,
          later,
          startOfToday: start,
          savedMemNotifications: notifications,
          periodCountByMemId: {
            1: weeklyTargetValue,
            2: weeklyTargetValue,
          },
        ),
        lessThan(0),
      );
    });

    test(
        'groups a weekly count on the usual notification day after a week from the last act',
        () {
      final section = memEnded(1, DateTime(2024, 10, 4, laterNotifyHour))
          .memListSectionDate(
        startOfToday,
        repeatOnWednesday(1, notifyHour),
        target: countTarget(
          memId: 1,
          value: weeklyTargetValue,
          period: Period.aWeek,
        ),
        todayCount: weeklyTargetValue,
      );

      expect(section, DateAndTime(2024, 10, 16));
    });

    test('keeps notifyAt order when the interval alone places the mem', () {
      Target daily(int memId) => countTarget(
            memId: memId,
            value: dailyTargetValue,
            period: Period.aDay,
            secondsAfterLastAct: 2 * hourSeconds,
          );
      final earlier = entity(
        id: 1,
        end: DateTime(2024, 10, 12, earlyNotifyHour),
        target: daily(1),
      );
      final later = entity(
        id: 2,
        end: DateTime(2024, 10, 12, middayHour),
        target: daily(2),
      );
      final notifications = [
        savedRepeatAtHourNotification(id: 1, memId: 1, hour: laterNotifyHour),
        savedRepeatAtHourNotification(id: 2, memId: 2, hour: laterNotifyHour),
      ];
      const counts = {1: belowDailyTarget, 2: belowDailyTarget};

      final listed = compareMemListEntries(
        earlier,
        later,
        startOfToday: startOfToday,
        savedMemNotifications: notifications,
        periodCountByMemId: counts,
      );
      final byNotifyAt = earlier
          .toDomain()
          .notifyAt(
            startOfToday,
            notifications
                .where((e) => e.value.memId == earlier.id)
                .map((e) => e.value),
            earlier.latestAct,
            target: earlier.target,
            todayCount: belowDailyTarget,
          )!
          .at
          .compareTo(
            later
                .toDomain()
                .notifyAt(
                  startOfToday,
                  notifications
                      .where((e) => e.value.memId == later.id)
                      .map((e) => e.value),
                  later.latestAct,
                  target: later.target,
                  todayCount: belowDailyTarget,
                )!
                .at,
          );

      expect(listed, byNotifyAt);
      expect(listed, lessThan(0));
    });
  });
}
