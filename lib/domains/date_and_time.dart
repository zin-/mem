import 'package:flutter/material.dart';

class DateAndTime extends DateTime {
  bool isAllDay = false;

  DateAndTime.now({bool allDay = false})
      : isAllDay = allDay,
        super.now();

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

  DateAndTime.fromDateTimeAndTimeOfDay(
    DateTime dateTime,
    TimeOfDay? timeOfDay,
  ) : super.now();

  TimeOfDay? time() => isAllDay ? null : TimeOfDay.fromDateTime(this);

  @override
  String toString() => '${super.toString()}, isAllDay: $isAllDay';
}
