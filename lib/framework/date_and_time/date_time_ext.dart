import 'package:flutter/material.dart';

extension DateTimeExt on DateTime {
  static DateTime startOfToday(TimeOfDay startOfDay, [DateTime? now]) {
    final current = now ?? DateTime.now();
    final nowTime = TimeOfDay.fromDateTime(current);
    return DateTime(
      current.year,
      current.month,
      current.day + (startOfDay.isBefore(nowTime) ? 0 : 1),
      startOfDay.hour,
      startOfDay.minute,
    );
  }
}
