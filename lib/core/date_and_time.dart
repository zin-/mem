// FIXME TimeOfDayを排除したい
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

  @Deprecated('use fromV2')
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

  DateAndTime.fromV2(
    DateTime dateTime, {
    DateTime? timeOfDay,
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
      : this.fromV2(
          DateTime.now(),
          // FIXME 同じnowを使う
          timeOfDay: allDay ? null : DateTime.now(),
        );

  DateTime get dateTime => DateTime(year, month, day);

  Map<String, dynamic> toMap() => {
        '_': super.toString(),
        'isAllDay': isAllDay,
      };

  @override
  String toString() => toMap().toString();
}
