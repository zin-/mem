import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

void main() {
  const startOfDay = TimeOfDay(hour: 5, minute: 0);

  group('Period.toPeriod', () {
    test('aDay uses startOfDay and offset', () {
      final now = DateAndTime(2026, 10, 13, 12, 0);

      final current = Period.aDay.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2026, 10, 13, 5, 0));
      expect(current.end, DateAndTime(2026, 10, 14, 5, 0));

      final previous = Period.aDay.toPeriod(now, startOfDay, offset: -1)!;
      expect(previous.start, DateAndTime(2026, 10, 12, 5, 0));
      expect(previous.end, DateAndTime(2026, 10, 13, 5, 0));
    });

    test('aDay before startOfDay belongs to previous day', () {
      final now = DateAndTime(2026, 10, 13, 3, 0);

      final current = Period.aDay.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2026, 10, 12, 5, 0));
      expect(current.end, DateAndTime(2026, 10, 13, 5, 0));
    });

    test('aWeek ends on the reference day', () {
      final now = DateAndTime(2026, 10, 13, 12, 0);

      final current = Period.aWeek.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2026, 10, 7, 5, 0));
      expect(current.end, DateAndTime(2026, 10, 14, 5, 0));

      final previous = Period.aWeek.toPeriod(now, startOfDay, offset: -1)!;
      expect(previous.start, DateAndTime(2026, 9, 30, 5, 0));
      expect(previous.end, DateAndTime(2026, 10, 7, 5, 0));
    });

    test('aMonth ends on the reference day', () {
      final now = DateAndTime(2026, 10, 13, 12, 0);

      final current = Period.aMonth.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2026, 9, 14, 5, 0));
      expect(current.end, DateAndTime(2026, 10, 14, 5, 0));

      final previous = Period.aMonth.toPeriod(now, startOfDay, offset: -1)!;
      expect(previous.start, DateAndTime(2026, 8, 14, 5, 0));
      expect(previous.end, DateAndTime(2026, 9, 14, 5, 0));
    });

    test('aMonth clamps when the previous month has no such day', () {
      final now = DateAndTime(2026, 3, 31, 12, 0);

      final current = Period.aMonth.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2026, 3, 1, 5, 0));
      expect(current.end, DateAndTime(2026, 4, 1, 5, 0));
    });

    test('threeMonth ends on the reference day', () {
      final now = DateAndTime(2026, 10, 13, 12, 0);

      final current = Period.threeMonth.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2026, 7, 14, 5, 0));
      expect(current.end, DateAndTime(2026, 10, 14, 5, 0));

      final previous =
          Period.threeMonth.toPeriod(now, startOfDay, offset: -1)!;
      expect(previous.start, DateAndTime(2026, 4, 14, 5, 0));
      expect(previous.end, DateAndTime(2026, 7, 14, 5, 0));
    });

    test('aYear ends on the reference day', () {
      final now = DateAndTime(2026, 10, 13, 12, 0);

      final current = Period.aYear.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2025, 10, 14, 5, 0));
      expect(current.end, DateAndTime(2026, 10, 14, 5, 0));

      final previous = Period.aYear.toPeriod(now, startOfDay, offset: -1)!;
      expect(previous.start, DateAndTime(2024, 10, 14, 5, 0));
      expect(previous.end, DateAndTime(2025, 10, 14, 5, 0));
    });

    test('all returns null', () {
      final now = DateAndTime(2026, 10, 13, 12, 0);
      expect(Period.all.toPeriod(now, startOfDay), isNull);
    });
  });

  group('DateAndTimePeriod.formatCompactRange', () {
    testWidgets('single day when start equals inclusive end', (tester) async {
      final localizations = await _localizations(tester);
      final period = Period.aDay.toPeriod(
        DateAndTime(2026, 10, 13, 12, 0),
        startOfDay,
      )!;

      expect(
        period.formatCompactRange(localizations),
        localizations.formatCompactDate(period.start),
      );
    });

    testWidgets('range uses inclusive end', (tester) async {
      final localizations = await _localizations(tester);
      final period = Period.aWeek.toPeriod(
        DateAndTime(2026, 10, 13, 12, 0),
        startOfDay,
      )!;
      final inclusiveEnd = period.end.subtract(const Duration(days: 1));

      expect(
        period.formatCompactRange(localizations),
        '${localizations.formatCompactDate(period.start)} – ${localizations.formatCompactDate(inclusiveEnd)}',
      );
    });
  });
}

Future<MaterialLocalizations> _localizations(WidgetTester tester) async {
  late MaterialLocalizations localizations;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          localizations = MaterialLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return localizations;
}
