import 'package:flutter/material.dart';

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
