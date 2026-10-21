import 'package:flutter/material.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

extension DateTimeExt on DateTime {
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
}
