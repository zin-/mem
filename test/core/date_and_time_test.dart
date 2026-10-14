import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

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
}
