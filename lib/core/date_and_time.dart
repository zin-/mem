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
    bool allDay = false,
  }) : this(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          allDay
              ? null
              : timeOfDay != null
                  ? timeOfDay.hour
                  : dateTime.hour,
          allDay
              ? null
              : timeOfDay != null
                  ? timeOfDay.minute
                  : dateTime.minute,
          null,
          null,
          null,
        );

  DateAndTime.now({bool allDay = false})
      : this.from(
          DateTime.now(),
          timeOfDay: allDay ? null : TimeOfDay.now(),
          allDay: allDay,
        );

  DateTime get dateTime => DateTime(year, month, day);

  // TimeOfDay? get timeOfDay => isAllDay ? null : TimeOfDay.fromDateTime(this);

  Map<String, dynamic> toMap() => {
        '_': super.toString(),
        'isAllDay': isAllDay,
      };

  @override
  String toString() => toMap().toString();
}
