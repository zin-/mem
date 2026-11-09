import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/targets/next_at_after_last_act.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

class MemNotifyAt {
  final DateTime at;

  MemNotifyAt._(this.at);

  static MemNotifyAt? of({
    required DateAndTimePeriod? period,
    required Act? scheduleAnchor,
    required DateTime startOfToday,
    Iterable<MemNotification>? memNotifications,
    Act? latestAct,
    Target? target,
    int todayCount = 0,
  }) {
    final scheduledNotifications = memNotifications?.where(
      (e) => e.isEnabled() && !e.isAfterActStarted(),
    );
    final chosen = _choose(
      withBase: _notificationAt(
        scheduledNotifications,
        startOfToday,
        scheduleAnchor,
      ),
      withoutBase: _notificationAt(
        scheduledNotifications,
        startOfToday,
        null,
      ),
      startOfDay: TimeOfDay.fromDateTime(startOfToday),
      target: target,
      todayCount: todayCount,
      latestAct: latestAct,
    );
    final at = _afterSkipFloor(
      _laterOf(_periodAt(period, startOfToday), chosen),
      latestAct,
      scheduledNotifications,
    );
    if (at == null) return null;
    return MemNotifyAt._(at);
  }

  static MemNotifyAt? repeat({
    required Iterable<MemNotification> memNotifications,
    required TimeOfDay startOfDay,
    required Act? latestAct,
    required Act? scheduleAnchor,
    required DateTime now,
    Target? target,
    int todayCount = 0,
  }) {
    if (latestAct?.isActive == true) return null;
    if (memNotifications.where((e) => !e.isAfterActStarted()).isEmpty) {
      return null;
    }

    final repeatAt = memNotifications
        .singleWhereOrNull((e) => e.isRepeated() && e.isEnabled())
        ?.time;
    final timeOfDay = repeatAt == null
        ? startOfDay
        : TimeOfDay(hour: 0, minute: (repeatAt / 60).floor());

    DateTime atTime(DateTime base) => base.copyWith(
          hour: timeOfDay.hour,
          minute: timeOfDay.minute,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );

    final withoutBase = atTime(now);
    final withBase = scheduleAnchor == null || !scheduleAnchor.isScheduleAnchor
        ? withoutBase
        : atTime(scheduleAnchor.period?.end ?? now).add(Duration(
            days: memNotifications
                    .singleWhereOrNull((e) => e.isRepeatByNDay())
                    ?.time ??
                1,
          ));

    var notifyAt = _choose(
      withBase: withBase,
      withoutBase: withoutBase,
      startOfDay: startOfDay,
      target: target,
      todayCount: todayCount,
      latestAct: latestAct,
    );

    while (notifyAt != null && now.compareTo(notifyAt) > 0) {
      notifyAt = notifyAt.add(const Duration(days: 1));
    }

    final daysOfWeeks =
        memNotifications.where((e) => e.isRepeatByDayOfWeek() && e.isEnabled());

    while (daysOfWeeks.isNotEmpty &&
        !daysOfWeeks.map((e) => e.time).contains(notifyAt?.weekday)) {
      notifyAt = notifyAt?.add(const Duration(days: 1));
    }

    return MemNotifyAt._(notifyAt!);
  }

  static DateTime? _choose({
    required DateTime? withBase,
    required DateTime? withoutBase,
    required TimeOfDay startOfDay,
    required Target? target,
    required int todayCount,
    required Act? latestAct,
  }) {
    if (target == null || !target.acceptsSecondsAfterLastAct) {
      return withBase;
    }
    if (todayCount >= target.value || latestAct?.isSkipped == true) {
      return withBase;
    }

    final end = latestAct?.period?.end;
    final intervalAt = NextAtAfterLastAct.of(
      target: target,
      latestAct: latestAct,
    )?.at;
    if (end != null &&
        intervalAt != null &&
        _sameLogicalDay(end, intervalAt, startOfDay)) {
      return intervalAt;
    }
    return withoutBase;
  }

  static DateTime? _notificationAt(
    Iterable<MemNotification>? scheduledNotifications,
    DateTime startOfToday,
    Act? anchor,
  ) =>
      scheduledNotifications == null || scheduledNotifications.isEmpty
          ? null
          : MemNotification.nextNotifyAt(
              scheduledNotifications,
              startOfToday,
              anchor,
            );

  static DateTime? _periodAt(
    DateAndTimePeriod? period,
    DateTime startOfToday,
  ) =>
      period?.start != null || period?.end != null
          ? period?.start != null && period?.end != null
              ? period!.start!.compareTo(startOfToday) < 0
                  ? period.end
                  : period.start
              : period?.start ?? period?.end
          : null;

  static DateTime? _laterOf(DateTime? a, DateTime? b) => v(
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

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  static DateTime? _afterSkipFloor(
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
    final repeatByNDay =
        scheduledNotifications.where((e) => e.isRepeatByNDay()).firstOrNull;
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

  static DateAndTime _timed(DateTime value) =>
      value is DateAndTime ? value : DateAndTime.from(value, timeOfDay: value);

  static bool _sameLogicalDay(DateTime a, DateTime b, TimeOfDay startOfDay) {
    final day = _timed(a).logicalDay(startOfDay);
    return _timed(b).isSameLogicalDay(day, startOfDay);
  }
}
