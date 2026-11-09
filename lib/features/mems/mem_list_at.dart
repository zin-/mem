import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mems/count_reference_act.dart';
import 'package:mem/features/mems/count_target.dart';
import 'package:mem/features/targets/next_at_after_last_act.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

class MemListAt {
  final DateTime at;

  MemListAt._(this.at);

  static MemListAt? of({
    required DateTime startOfToday,
    required DateTime? notifyAt,
    required Target? target,
    required Act? latestAct,
    Act? scheduleAnchorAct,
    Iterable<MemNotification>? notifications,
    int periodCount = 0,
  }) {
    final startOfDay = TimeOfDay.fromDateTime(startOfToday);
    final countTarget = CountTarget.of(target, periodCount);
    final chosen = countTarget == null
        ? notifyAt
        : _at(
            countTarget: countTarget,
            notifyAt: notifyAt,
            latestAct: latestAct,
            scheduleAnchorAct: scheduleAnchorAct,
            notifications: notifications,
            startOfToday: startOfToday,
            startOfDay: startOfDay,
          );
    if (chosen == null) return null;
    return MemListAt._(chosen);
  }

  static DateTime? _at({
    required CountTarget countTarget,
    required DateTime? notifyAt,
    required Act? latestAct,
    required Act? scheduleAnchorAct,
    required Iterable<MemNotification>? notifications,
    required DateTime startOfToday,
    required TimeOfDay startOfDay,
  }) {
    final target = countTarget.target;
    final reached = countTarget.count >= countTarget.targetValue;
    if (target.period == Period.aDay) {
      if (reached) {
        return _onLogicalDay(
          _logicalToday(startOfToday).shiftCalendarDays(1),
          _clock(notifications, startOfDay),
          startOfDay,
        );
      }
      return NextAtAfterLastAct.of(
            target: target,
            latestAct: latestAct,
            scheduleAnchorAct: scheduleAnchorAct,
          )?.at ??
          notifyAt;
    }
    if (target.period == Period.aWeek) {
      final reference = CountReferenceAct.of(
        latestAct: latestAct,
        scheduleAnchorAct: scheduleAnchorAct,
      );
      if (reference == null ||
          !reference.isWithinWeek(startOfToday, startOfDay)) {
        return notifyAt;
      }
      if (reached) {
        return _onLogicalDay(
          reference
              .logicalDay(startOfDay)
              .shiftCalendarDays(DateTime.daysPerWeek),
          _clock(notifications, startOfDay),
          startOfDay,
        );
      }
      return _onLogicalDay(
        _logicalToday(startOfToday).shiftCalendarDays(1),
        _clock(notifications, startOfDay),
        startOfDay,
      );
    }
    return notifyAt;
  }

  static DateAndTime _logicalToday(DateTime startOfToday) => DateAndTime(
        startOfToday.year,
        startOfToday.month,
        startOfToday.day,
      );

  static TimeOfDay _clock(
    Iterable<MemNotification>? notifications,
    TimeOfDay startOfDay,
  ) =>
      notifications
          ?.whereType<RepeatMemNotification>()
          .singleWhereOrNull((notification) => notification.isEnabled())
          ?.timeOfDay ??
      startOfDay;

  static DateTime _onLogicalDay(
    DateAndTime logicalDay,
    TimeOfDay time,
    TimeOfDay startOfDay,
  ) {
    final day = time.isBefore(startOfDay)
        ? logicalDay.shiftCalendarDays(1)
        : logicalDay;
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }
}
