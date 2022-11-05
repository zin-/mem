import 'package:flutter/material.dart';

class DateAndTime extends DateTime {
  bool isAllDay = false;

  DateAndTime(int year,
      [int month = 1,
      int day = 1,
      int? hour,
      int? minute,
      int? second,
      int? millisecond,
      int? microsecond])
      : isAllDay = hour == null &&
            minute == null &&
            second == null &&
            millisecond == null &&
            microsecond == null,
        super(
          year,
          month,
          day,
          hour ?? 0,
          minute ?? 0,
          second ?? 0,
          millisecond ?? 0,
          microsecond ?? 0,
        );

  DateAndTime.from(
    DateTime dateTime, {
    TimeOfDay? timeOfDay,
  }) : this(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          timeOfDay?.hour,
          timeOfDay?.minute,
          null,
          null,
          null,
        );

  DateAndTime.now({bool allDay = false})
      : this.from(
          DateTime.now(),
          timeOfDay: allDay ? null : TimeOfDay.now(),
        );

  DateTime get dateTime => DateTime(year, month, day);

  TimeOfDay? get timeOfDay => isAllDay ? null : TimeOfDay.fromDateTime(this);

  @override
  String toString() => '${super.toString()}, isAllDay: $isAllDay';
}
