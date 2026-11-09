import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/targets/next_at_after_last_act.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

class MemListClock {
  final DateTime at;

  MemListClock._(this.at);

  static MemListClock? of({
    required Target? target,
    required Act? latestAct,
    required Act? scheduleAnchorAct,
    required Iterable<MemNotification> notifications,
    required TimeOfDay startOfDay,
    required int todayCount,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (_dailyCountAdvanced(target, todayCount)) {
      final next = _nextDayNotifyAt(notifications, startOfDay, current);
      if (next == null) return null;
      return MemListClock._(next);
    }

    final interval = target == null
        ? null
        : NextAtAfterLastAct.of(
            target: target,
            latestAct: latestAct,
            scheduleAnchorAct: scheduleAnchorAct,
          )?.at;
    if (interval == null) return null;
    return MemListClock._(interval);
  }

  static bool _dailyCountAdvanced(Target? target, int todayCount) =>
      target != null &&
      target.targetUnit == TargetUnit.count &&
      target.period == Period.aDay &&
      target.value > 0 &&
      todayCount >= target.value;

  static DateTime? _nextDayNotifyAt(
    Iterable<MemNotification> notifications,
    TimeOfDay startOfDay,
    DateTime now,
  ) {
    final time = notifications
        .whereType<RepeatMemNotification>()
        .singleWhereOrNull((notification) => notification.isEnabled())
        ?.timeOfDay;
    if (time == null) return null;

    final start = DateTimeExt.startOfToday(startOfDay, now);
    final startOfNextDay =
        DateAndTime.from(start, timeOfDay: start).shiftCalendarDays(1);
    final onThatDay = DateTime(
      startOfNextDay.year,
      startOfNextDay.month,
      startOfNextDay.day,
      time.hour,
      time.minute,
    );
    if (!onThatDay.isBefore(startOfNextDay)) return onThatDay;

    final shifted =
        DateAndTime.from(onThatDay, timeOfDay: onThatDay).shiftCalendarDays(1);
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      time.hour,
      time.minute,
    );
  }
}
