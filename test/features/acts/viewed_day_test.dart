import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/viewed_day.dart';

void main() {
  const startOfDay = TimeOfDay(hour: 5, minute: 0);

  test('viewed day ends at the next startOfDay', () {
    final window = viewedDayWindow(DateTime(2026, 10, 30), startOfDay);

    expect(window.start, DateTime(2026, 10, 30, 5));
    expect(window.end, DateTime(2026, 10, 31, 5));
  });
}
