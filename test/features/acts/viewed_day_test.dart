import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/viewed_day.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

void main() {
  const startOfDay = TimeOfDay(hour: 5, minute: 0);

  test('viewed day ends at the next startOfDay', () {
    final window = viewedDayWindow(DateTime(2026, 10, 30), startOfDay);

    expect(window.start, DateTime(2026, 10, 30, 5));
    expect(window.end, DateTime(2026, 10, 31, 5));
  });

  test('logical today is the only day treated as today', () {
    final today = logicalToday(startOfDay);

    expect(isViewedDayToday(today, startOfDay), isTrue);
    expect(
      isViewedDayToday(today.subtract(const Duration(days: 1)), startOfDay),
      isFalse,
    );
  });

  test('4:00 treats the previous day as today', () {
    final now = DateAndTime(2026, 11, 6, 4);

    expect(isViewedDayToday(DateTime(2026, 11, 5), startOfDay, now), isTrue);
    expect(isViewedDayToday(DateTime(2026, 11, 6), startOfDay, now), isFalse);
  });

  test('exactly 5:00 treats that calendar day as today', () {
    final now = DateAndTime(2026, 11, 6, 5);

    expect(isViewedDayToday(DateTime(2026, 11, 6), startOfDay, now), isTrue);
  });

  test('23:59 with midnight start treats that calendar day as today', () {
    // 23:59 より後の開始時刻は同じ暦日に置けない
    const midnight = TimeOfDay(hour: 0, minute: 0);
    final now = DateAndTime(2026, 11, 6, 23, 59);

    expect(isViewedDayToday(DateTime(2026, 11, 6), midnight, now), isTrue);
  });

  test('3:00 on the 1st treats the previous month as current', () {
    final now = DateAndTime(2026, 11, 1, 3);

    expect(
      isSameLogicalMonth(DateTime(2026, 10, 1), startOfDay, now),
      isTrue,
    );
    expect(
      isSameLogicalMonth(DateTime(2026, 11, 1), startOfDay, now),
      isFalse,
    );
  });

  test('exactly 5:00 on the 1st treats that month as current', () {
    final now = DateAndTime(2026, 11, 1, 5);

    expect(
      isSameLogicalMonth(DateTime(2026, 11, 1), startOfDay, now),
      isTrue,
    );
  });

  test('3:00 on January 1 treats the previous December as current', () {
    final now = DateAndTime(2026, 1, 1, 3);

    expect(
      isSameLogicalMonth(DateTime(2025, 12, 1), startOfDay, now),
      isTrue,
    );
    expect(
      isSameLogicalMonth(DateTime(2026, 1, 1), startOfDay, now),
      isFalse,
    );
  });
}
