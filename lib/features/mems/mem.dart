import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_list_at.dart';
import 'package:mem/features/mems/mem_notify_at.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/framework/notifications/schedule.dart';

// FIXME uuidとかにする
typedef MemId = int?;

class Mem {
  final MemId id;

  final String name;
  final DateTime? doneAt;
  final DateAndTimePeriod? period;
  final Act? latestAct;
  final Act? scheduleAnchorAct;

  Mem(
    this.id,
    this.name,
    this.doneAt,
    this.period, {
    this.latestAct,
    this.scheduleAnchorAct,
  });

  bool get isArchived => false;

  bool get isDone => doneAt != null;

  Mem done(DateTime when) => Mem(id, name, when, period,
      latestAct: latestAct, scheduleAnchorAct: scheduleAnchorAct);

  Mem undone() => Mem(id, name, null, period,
      latestAct: latestAct, scheduleAnchorAct: scheduleAnchorAct);

  Mem withPeriod(DateAndTimePeriod? period) => Mem(id, name, doneAt, period,
      latestAct: latestAct, scheduleAnchorAct: scheduleAnchorAct);

  Act? get resolvedScheduleAnchor => scheduleAnchorForNotifications(
        latestAct: latestAct,
        scheduleAnchorAct: scheduleAnchorAct,
      );

  DateAndTime? memListSectionDate(
    DateTime startOfToday,
    Iterable<MemNotification>? memNotifications, {
    Target? target,
    int todayCount = 0,
  }) {
    final at = memListAt(
      startOfToday,
      memNotifications,
      target: target,
      periodCount: todayCount,
    )?.at;
    if (at == null) return null;
    final scheduledNotifications = memNotifications?.where(
      (e) => !e.isAfterActStarted(),
    );
    if (scheduledNotifications != null &&
        scheduledNotifications.isNotEmpty &&
        TimeOfDay.fromDateTime(at)
            .isBefore(TimeOfDay.fromDateTime(startOfToday))) {
      return DateAndTime(
        at.year,
        at.month,
        at.day,
      ).subtract(const Duration(days: 1));
    }
    return DateAndTime(
      at.year,
      at.month,
      at.day,
    );
  }

  MemListAt? memListAt(
    DateTime startOfToday,
    Iterable<MemNotification>? memNotifications, {
    Target? target,
    int periodCount = 0,
  }) =>
      v(
        () => MemListAt.of(
          notifyAt(
            startOfToday,
            memNotifications,
            latestAct,
            target: target,
            todayCount: periodCount,
          ),
        ),
        {
          'this': this,
          'startOfToday': startOfToday,
          'memNotifications': memNotifications,
          'target': target,
          'periodCount': periodCount,
        },
      );

  MemNotifyAt? notifyAt(
    DateTime startOfToday,
    Iterable<MemNotification>? memNotifications,
    Act? latestAct, {
    Target? target,
    int todayCount = 0,
  }) =>
      v(
        () => MemNotifyAt.of(
          period: period,
          scheduleAnchor: resolvedScheduleAnchor,
          startOfToday: startOfToday,
          memNotifications: memNotifications,
          latestAct: latestAct,
          target: target,
          todayCount: todayCount,
        ),
        {
          'this': this,
          'startOfToday': startOfToday,
          'memNotifications': memNotifications,
          'latestAct': latestAct,
          'target': target,
          'todayCount': todayCount,
        },
      );

  Iterable<Schedule> periodSchedules(
    TimeOfDay startOfDay,
  ) =>
      v(
        () {
          return [
            Schedule.of(
              id,
              period?.start?.isAllDay == true
                  ? DateTime(
                      period!.start!.year,
                      period!.start!.month,
                      period!.start!.day,
                      startOfDay.hour,
                      startOfDay.minute,
                    )
                  : period?.start,
              NotificationType.startMem,
            ),
            Schedule.of(
              id,
              period?.end?.isAllDay == true
                  ? DateTime(
                      period!.end!.year,
                      period!.end!.month,
                      period!.end!.day,
                      startOfDay.hour,
                      startOfDay.minute,
                    )
                      .add(const Duration(days: 1))
                      .subtract(const Duration(minutes: 1))
                  : period?.end,
              NotificationType.endMem,
            ),
          ];
        },
        {
          'this': this,
          'startOfDay': startOfDay,
        },
      );
}
