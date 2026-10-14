import 'package:flutter/material.dart';
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

    test('a month stays one point per day', () {
      final summary = ActsSummary(
        [_actOn(2026, 3, 1)],
        AggregationType.count,
        period: DateAndTimePeriod(
          start: DateAndTime(2026, 3, 1, 5),
          end: DateAndTime(2026, 4, 1, 5),
        ),
      );

      final values = summary.groupedListByDate.values.toList();
      expect(values, hasLength(31));
      expect(values.first, 1);
      expect(values.skip(1), everyElement(0));
    });

    test('three months group days of the same week', () {
      final summary = ActsSummary(
        [
          _actOn(2026, 7, 14),
          _actOn(2026, 7, 15),
        ],
        AggregationType.count,
        period: DateAndTimePeriod(
          start: DateAndTime(2026, 7, 14, 5),
          end: DateAndTime(2026, 10, 14, 5),
        ),
      );

      final values = summary.groupedListByDate.values.toList();
      expect(values.length, lessThan(31));
      expect(values.length, greaterThan(10));
      expect(values.first, 2);
      expect(values.skip(1), everyElement(0));
    });

    test('a year groups days of the same week', () {
      final summary = ActsSummary(
        [
          _actOn(2025, 10, 1),
          _actOn(2025, 10, 2),
          _actOn(2026, 4, 1),
        ],
        AggregationType.count,
        period: DateAndTimePeriod(
          start: DateAndTime(2025, 10, 1, 5),
          end: DateAndTime(2026, 10, 1, 5),
        ),
      );

      final values = summary.groupedListByDate.values.toList();
      expect(values.length, lessThan(365));
      expect(values.length, greaterThan(50));
      expect(values.first, 2);
      expect(values.where((value) => value == 1), hasLength(1));
      expect(values.where((value) => value == 0), hasLength(values.length - 2));
    });

    test('same week number in another year stays separate', () {
      final summary = ActsSummary(
        [
          _actOn(2025, 10, 14),
          _actOn(2026, 10, 13),
        ],
        AggregationType.count,
        period: DateAndTimePeriod(
          start: DateAndTime(2025, 10, 14, 5),
          end: DateAndTime(2026, 10, 14, 5),
        ),
      );

      final values = summary.groupedListByDate.values.toList();
      expect(values.where((value) => value == 1), hasLength(2));
      expect(values.where((value) => value > 1), isEmpty);
    });

    test('days in the same week across the new year stay together', () {
      final summary = ActsSummary(
        [
          _actOn(2025, 12, 31),
          _actOn(2026, 1, 1),
        ],
        AggregationType.count,
        period: DateAndTimePeriod(
          start: DateAndTime(2025, 12, 1, 5),
          end: DateAndTime(2026, 2, 1, 5),
        ),
      );

      expect(summary.groupedListByDate[DateAndTime(2025, 12, 29)], 2);
      expect(
        summary.groupedListByDate.values.where((value) => value > 0),
        [2],
      );
    });

    test('act before startOfDay belongs to the previous day', () {
      const startOfDay = TimeOfDay(hour: 5, minute: 0);
      final summary = ActsSummary(
        [
          FinishedAct(
            1,
            DateAndTime(2026, 10, 14, 3),
            DateAndTime(2026, 10, 14, 4),
          ),
        ],
        AggregationType.count,
        period: DateAndTimePeriod(
          start: DateAndTime(2026, 10, 13, 5),
          end: DateAndTime(2026, 10, 14, 5),
        ),
        startOfDay: startOfDay,
      );

      expect(summary.groupedListByDate.keys.toList(), [
        DateAndTime(2026, 10, 13),
      ]);
      expect(summary.groupedListByDate.values.toList(), [1]);
    });
  });
}

Act _actOn(int year, int month, int day) => FinishedAct(
      1,
      DateAndTime(year, month, day, 10),
      DateAndTime(year, month, day, 11),
    );
