import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

void main() {
  group('ActsSummary', () {
    test('fills leading, middle, and trailing days in the period with 0', () {
      final summary = ActsSummary(
        [
          _actOn(2026, 10, 2),
          _actOn(2026, 10, 2),
          _actOn(2026, 10, 4),
        ],
        AggregationType.count,
        period: DateAndTimePeriod(
          start: DateAndTime(2026, 10, 1, 5),
          end: DateAndTime(2026, 10, 6, 5),
        ),
      );

      expect(summary.groupedListByDate.keys.toList(), [
        DateAndTime(2026, 10, 1),
        DateAndTime(2026, 10, 2),
        DateAndTime(2026, 10, 3),
        DateAndTime(2026, 10, 4),
        DateAndTime(2026, 10, 5),
      ]);
      expect(summary.groupedListByDate.values.toList(), [0, 2, 0, 1, 0]);
      expect(summary.min, 0);
      expect(summary.average, closeTo(0.6, 0.001));
    });

    test('fills every day with 0 when the period has no acts', () {
      final summary = ActsSummary(
        <Act>[],
        AggregationType.count,
        period: DateAndTimePeriod(
          start: DateAndTime(2026, 10, 1, 5),
          end: DateAndTime(2026, 10, 4, 5),
        ),
      );

      expect(summary.groupedListByDate.values.toList(), [0, 0, 0]);
      expect(summary.min, 0);
      expect(summary.average, 0);
    });

    test('all period fills only gaps between the first and last act', () {
      final summary = ActsSummary(
        [
          _actOn(2026, 10, 4),
          _actOn(2026, 10, 2),
          _actOn(2026, 10, 2),
        ],
        AggregationType.count,
      );

      expect(summary.groupedListByDate.keys.toList(), [
        DateAndTime(2026, 10, 2),
        DateAndTime(2026, 10, 3),
        DateAndTime(2026, 10, 4),
      ]);
      expect(summary.groupedListByDate.values.toList(), [2, 0, 1]);
      expect(summary.min, 0);
      expect(summary.average, 1);
    });

    test('empty weeks stay 0 after filling days longer than four weeks', () {
      final summary = ActsSummary(
        [_actOn(2026, 10, 1)],
        AggregationType.count,
        period: DateAndTimePeriod(
          start: DateAndTime(2026, 10, 1, 5),
          end: DateAndTime(2026, 10, 30, 5),
        ),
      );

      final values = summary.groupedListByDate.values.toList();
      expect(values.length, greaterThan(1));
      expect(values.length, lessThan(29));
      expect(values.first, 1);
      expect(values.skip(1), everyElement(0));
    });
  });
}

Act _actOn(int year, int month, int day) => FinishedAct(
      1,
      DateAndTime(year, month, day, 10),
      DateAndTime(year, month, day, 11),
    );
