import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
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

  Mem done(DateTime when) =>
      Mem(id, name, when, period,
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
    Iterable<MemNotification>? memNotifications,
  ) {
    final nextNotifyAt = notifyAt(
      startOfToday,
      memNotifications,
      latestAct,
    );
    if (nextNotifyAt == null) return null;
    final scheduledNotifications = memNotifications?.where(
      (e) => !e.isAfterActStarted(),
    );
    if (scheduledNotifications != null &&
        scheduledNotifications.isNotEmpty &&
        TimeOfDay.fromDateTime(nextNotifyAt)
            .isBefore(TimeOfDay.fromDateTime(startOfToday))) {
      return DateAndTime(
        nextNotifyAt.year,
        nextNotifyAt.month,
        nextNotifyAt.day,
      ).subtract(const Duration(days: 1));
    }
    return DateAndTime(
      nextNotifyAt.year,
      nextNotifyAt.month,
      nextNotifyAt.day,
    );
  }

  DateTime? notifyAt(
    DateTime startOfToday,
    Iterable<MemNotification>? memNotifications,
    Act? latestAct,
  ) =>
      v(
        () {
          final scheduledNotifications = memNotifications?.where(
            (e) => !e.isAfterActStarted(),
          );
          final notifyAt = _selectNonNullOrGreater(
            period?.start != null || period?.end != null
                ? period?.start != null && period?.end != null
                    ? period!.start!.compareTo(startOfToday) < 0
                        ? period?.end
                        : period?.start
                    : period?.start ?? period?.end
                : null,
            scheduledNotifications == null || scheduledNotifications.isEmpty
                ? null
                : MemNotification.nextNotifyAt(
                    scheduledNotifications,
                    startOfToday,
                    resolvedScheduleAnchor,
                  ),
          );
          return _notifyAtAfterSkipFloor(
            notifyAt,
            latestAct,
            scheduledNotifications,
          );
        },
        {
          'this': this,
          'startOfToday': startOfToday,
          'memNotifications': memNotifications,
          'latestAct': latestAct,
        },
      );

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  static DateTime? _notifyAtAfterSkipFloor(
    DateTime? notifyAt,
    Act? latestAct,
    Iterable<MemNotification>? scheduledNotifications,
  ) {
    if (notifyAt == null || latestAct?.isSkipped != true) {
      return notifyAt;
    }
    final skipEnd = latestAct!.period?.end;
    if (skipEnd == null) {
      return notifyAt;
    }
    final skipDay = _dateOnly(skipEnd.dateTime);
    if (_dateOnly(notifyAt).compareTo(skipDay) > 0) {
      return notifyAt;
    }
    if (scheduledNotifications == null || scheduledNotifications.isEmpty) {
      return notifyAt;
    }

    var result = notifyAt;
    final repeatByNDay = scheduledNotifications
        .where((e) => e.isRepeatByNDay())
        .firstOrNull;
    if (repeatByNDay != null) {
      final nDays = repeatByNDay.time ?? 1;
      while (_dateOnly(result).compareTo(skipDay) <= 0) {
        result = DateTime(
          result.year,
          result.month,
          result.day + nDays,
          result.hour,
          result.minute,
        );
      }
      return result;
    }

    final repeatByDayOfWeekWeekdays = scheduledNotifications
        .where((e) => e.isRepeatByDayOfWeek())
        .map((e) => e.time)
        .whereType<int>()
        .toList();
    if (repeatByDayOfWeekWeekdays.isNotEmpty) {
      while (_dateOnly(result).compareTo(skipDay) <= 0 ||
          !repeatByDayOfWeekWeekdays.contains(result.weekday)) {
        result = result.add(const Duration(days: 1));
      }
      return result;
    }

    if (scheduledNotifications.any((e) => e.isRepeated())) {
      while (_dateOnly(result).compareTo(skipDay) <= 0) {
        result = result.add(const Duration(days: 1));
      }
    }

    return result;
  }

  DateTime? _selectNonNullOrGreater(
    DateTime? a,
    DateTime? b,
  ) =>
      v(
        () {
          if (a == null) return b;
          if (b == null) return a;
          return a.compareTo(b) > 0 ? a : b;
        },
        {
          'a': a,
          'b': b,
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
