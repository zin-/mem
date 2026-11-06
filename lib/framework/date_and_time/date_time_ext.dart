import 'package:flutter/material.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

extension DateTimeExt on DateTime {
  // 0 時の暦日に logicalDay を使うと、startOfDay より前なので前日になる
  WithStartAndEnd dayPeriod(TimeOfDay startOfDay) {
    final start = DateAndTime(
      year,
      month,
      day,
      startOfDay.hour,
      startOfDay.minute,
    );
    return WithStartAndEnd(start, start.shiftCalendarDays(1));
  }

  static DateTime startOfToday(TimeOfDay startOfDay, [DateTime? now]) {
    final current = now ?? DateTime.now();
    return DateTime(
      current.year,
      current.month,
      current.day,
      startOfDay.hour,
      startOfDay.minute,
    ).subtract(Duration(
      days: startOfDay.isBefore(TimeOfDay.fromDateTime(current)) ? 0 : 1,
    ));
  }
}

extension DateAndTimeExt on DateAndTime {
  DateAndTime logicalDay(TimeOfDay startOfDay) {
    final date = DateAndTime(year, month, day);
    if (!isAllDay && TimeOfDay.fromDateTime(this).isBefore(startOfDay)) {
      return date.shiftCalendarDays(-1);
    }
    return date;
  }

  bool isSameLogicalDay(DateTime day, TimeOfDay startOfDay) {
    final today = logicalDay(startOfDay);
    return day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
  }

  bool isSameLogicalMonth(DateTime month, TimeOfDay startOfDay) {
    final today = logicalDay(startOfDay);
    return month.year == today.year && month.month == today.month;
  }
}
