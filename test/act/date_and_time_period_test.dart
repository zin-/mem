import 'package:flutter_test/flutter_test.dart';
import 'package:mem/act/domain/date_and_time_period.dart';
import 'package:mem/domain/date_and_time.dart';

void main() {
  group('Create instance', () {
    test(': with start', () {
      final start = DateAndTime.now();
      final dateAndTimePeriod = DateAndTimePeriod(
        start: start,
      );

      expect(dateAndTimePeriod.start, start);
      expect(dateAndTimePeriod.end, null);
    });
    test(': with end', () {
      final end = DateAndTime.now();
      final dateAndTimePeriod = DateAndTimePeriod(
        end: end,
      );

      expect(dateAndTimePeriod.start, null);
      expect(dateAndTimePeriod.end, end);
    });
    test(': with start and end', () {
      final now = DateAndTime.now();
      final dateAndTimePeriod = DateAndTimePeriod(start: now, end: now);

      expect(dateAndTimePeriod.start, now);
      expect(dateAndTimePeriod.end, now);
    });

    test(': start and end are null', () {
      expect(() => DateAndTimePeriod(), throwsAssertionError);
    });
    test(': start is after end', () {
      final start = DateAndTime.now();
      final end = DateAndTime.from(start.subtract(const Duration(days: 1)));

      expect(
        () => DateAndTimePeriod(start: start, end: end),
        throwsAssertionError,
      );
    });

    test(': startNow', () {
      final now = DateAndTime.now();

      final dateAndTimePeriod = DateAndTimePeriod.startNow();

      expect(dateAndTimePeriod.start, now);
      expect(dateAndTimePeriod.end, null);
    });
  });
}
