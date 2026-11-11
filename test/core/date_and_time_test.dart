import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';

void main() {
  group('Create instance', () {
    group(': now', () {
      test(
        ': allDay is false',
        () {
          final dateAndTime = DateAndTime.now();
          final dateTime = DateTime.fromMicrosecondsSinceEpoch(
              dateAndTime.microsecondsSinceEpoch);

          expect(dateAndTime, isA<DateAndTime>());
          expect(dateAndTime, isA<DateTime>());

          expect(
            dateAndTime.microsecondsSinceEpoch,
            dateTime.microsecondsSinceEpoch,
          );
          expect(dateAndTime.isAllDay, false);
        },
      );

      test(
        ': allDay is true',
        () {
          final dateAndTime = DateAndTime.now(allDay: true);
          final dateTime = DateTime.fromMicrosecondsSinceEpoch(
            dateAndTime.microsecondsSinceEpoch,
          );

          expect(dateAndTime, isA<DateAndTime>());
          expect(dateAndTime, isA<DateTime>());

          expect(
            dateAndTime.microsecondsSinceEpoch,
            dateTime.microsecondsSinceEpoch,
          );
          expect(dateAndTime.isAllDay, true);
        },
      );
    });
  });

  test(
    'toString',
    () {
      final dateAndTime = DateAndTime(2022, 11, 6, 14, 49);

      expect(
        dateAndTime.toString(),
        '{_: 2022-11-06 14:49:00.000, isAllDay: false}',
      );
    },
  );

  group('shiftCalendarDays', () {
    test('moves by calendar date and keeps the time', () {
      final shifted = DateAndTime(2026, 1, 31, 5, 0).shiftCalendarDays(1);

      expect(shifted, DateAndTime(2026, 2, 1, 5, 0));
      expect(shifted.isAllDay, false);
    });

    test('all-day stays all-day', () {
      final shifted = DateAndTime(2026, 10, 13).shiftCalendarDays(-1);

      expect(shifted, DateAndTime(2026, 10, 12));
      expect(shifted.isAllDay, true);
    });
  });

  group('weekNumber', () {
    test('uses calendar date, not local duration', () {
      expect(DateAndTime(2024, 1, 1).weekNumber, 1);
      expect(DateAndTime(2024, 7, 1).weekNumber, 27);
      expect(
        DateAndTime(2024, 7, 1, 23).weekNumber,
        DateAndTime(2024, 7, 1).weekNumber,
      );
    });
  });

  group('dayPeriod', () {
    const startOfDay = TimeOfDay(hour: 5, minute: 0);

    test('ends at the next startOfDay', () {
      final window = DateTime(2026, 10, 30).dayPeriod(startOfDay);

      expect(window.start, DateTime(2026, 10, 30, 5));
      expect(window.end, DateTime(2026, 10, 31, 5));
    });
  });

  group('isSameLogicalDay', () {
    const startOfDay = TimeOfDay(hour: 5, minute: 0);

    test('logical today is the only day treated as today', () {
      final now = DateAndTime(2026, 11, 6, 12);

      expect(now.isSameLogicalDay(DateTime(2026, 11, 6), startOfDay), isTrue);
      expect(now.isSameLogicalDay(DateTime(2026, 11, 5), startOfDay), isFalse);
    });

    test('4:00 treats the previous day as today', () {
      final now = DateAndTime(2026, 11, 6, 4);

      expect(now.isSameLogicalDay(DateTime(2026, 11, 5), startOfDay), isTrue);
      expect(now.isSameLogicalDay(DateTime(2026, 11, 6), startOfDay), isFalse);
    });

    test('exactly 5:00 treats that calendar day as today', () {
      final now = DateAndTime(2026, 11, 6, 5);

      expect(now.isSameLogicalDay(DateTime(2026, 11, 6), startOfDay), isTrue);
    });

    test('23:59 with midnight start treats that calendar day as today', () {
      // 23:59 より後の開始時刻は同じ暦日に置けない
      const midnight = TimeOfDay(hour: 0, minute: 0);
      final now = DateAndTime(2026, 11, 6, 23, 59);

      expect(now.isSameLogicalDay(DateTime(2026, 11, 6), midnight), isTrue);
    });
  });

  group('isSameLogicalMonth', () {
    const startOfDay = TimeOfDay(hour: 5, minute: 0);

    test('3:00 on the 1st treats the previous month as current', () {
      final now = DateAndTime(2026, 11, 1, 3);

      expect(now.isSameLogicalMonth(DateTime(2026, 10, 1), startOfDay), isTrue);
      expect(
        now.isSameLogicalMonth(DateTime(2026, 11, 1), startOfDay),
        isFalse,
      );
    });

    test('exactly 5:00 on the 1st treats that month as current', () {
      final now = DateAndTime(2026, 11, 1, 5);

      expect(now.isSameLogicalMonth(DateTime(2026, 11, 1), startOfDay), isTrue);
    });

    test('3:00 on January 1 treats the previous December as current', () {
      final now = DateAndTime(2026, 1, 1, 3);

      expect(
        now.isSameLogicalMonth(DateTime(2025, 12, 1), startOfDay),
        isTrue,
      );
      expect(now.isSameLogicalMonth(DateTime(2026, 1, 1), startOfDay), isFalse);
    });
  });
}
