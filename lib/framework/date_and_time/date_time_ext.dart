import 'package:flutter/material.dart';

extension DateTimeExt on DateTime {
  static DateTime startOfToday(TimeOfDay startOfDay) {
    final now = DateTime.now();
    final nowTime = TimeOfDay.fromDateTime(now);
    return DateTime(
      now.year,
      now.month,
      now.day + (startOfDay.isBefore(nowTime) ? 0 : 1),
      startOfDay.hour,
      startOfDay.minute,
    );
  }
}
