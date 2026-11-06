import 'package:flutter/material.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

DateTime logicalToday(TimeOfDay startOfDay) {
  final start = DateTimeExt.startOfToday(startOfDay);
  return DateTime(start.year, start.month, start.day);
}

DateTime logicalGroupDate(
  DateAndTime start,
  TimeOfDay startOfDay,
  bool isDateView,
) {
  final day = start.logicalDay(startOfDay);
  return DateTime(day.year, day.month, isDateView ? day.day : 1);
}

WithStartAndEnd viewedDayWindow(DateTime viewedDay, TimeOfDay startOfDay) {
  // 行の日付は 0 時。startOfDay より前を Period.aDay に渡すと前日になる
  final atStartOfDay = DateAndTime(
    viewedDay.year,
    viewedDay.month,
    viewedDay.day,
    startOfDay.hour,
    startOfDay.minute,
  );
  return Period.aDay.toPeriod(atStartOfDay, startOfDay)!;
}

bool isViewedDayToday(
  DateTime viewedDay,
  TimeOfDay startOfDay, [
  DateAndTime? now,
]) {
  final today = Period.aDay.toPeriod(now ?? DateAndTime.now(), startOfDay)!;
  return today.start == viewedDayWindow(viewedDay, startOfDay).start;
}

bool isSameLogicalMonth(
  DateTime groupDate,
  TimeOfDay startOfDay, [
  DateAndTime? now,
]) {
  final today = (now ?? DateAndTime.now()).logicalDay(startOfDay);
  return groupDate.year == today.year && groupDate.month == today.month;
}
