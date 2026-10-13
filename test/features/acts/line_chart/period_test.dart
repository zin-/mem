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

    test('aWeek is Monday-aligned with offset', () {
      // 2026-10-13 is Tuesday
      final now = DateAndTime(2026, 10, 13, 12, 0);

      final current = Period.aWeek.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2026, 10, 12, 5, 0));
      expect(current.end, DateAndTime(2026, 10, 19, 5, 0));

      final previous = Period.aWeek.toPeriod(now, startOfDay, offset: -1)!;
      expect(previous.start, DateAndTime(2026, 10, 5, 5, 0));
      expect(previous.end, DateAndTime(2026, 10, 12, 5, 0));
    });

    test('aMonth is calendar month with offset', () {
      final now = DateAndTime(2026, 10, 13, 12, 0);

      final current = Period.aMonth.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2026, 10, 1, 5, 0));
      expect(current.end, DateAndTime(2026, 11, 1, 5, 0));

      final previous = Period.aMonth.toPeriod(now, startOfDay, offset: -1)!;
      expect(previous.start, DateAndTime(2026, 9, 1, 5, 0));
      expect(previous.end, DateAndTime(2026, 10, 1, 5, 0));
    });

    test('threeMonth is last 3 calendar months with offset', () {
      final now = DateAndTime(2026, 10, 13, 12, 0);

      final current = Period.threeMonth.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2026, 8, 1, 5, 0));
      expect(current.end, DateAndTime(2026, 11, 1, 5, 0));

      final previous = Period.threeMonth.toPeriod(now, startOfDay, offset: -1)!;
      expect(previous.start, DateAndTime(2026, 5, 1, 5, 0));
      expect(previous.end, DateAndTime(2026, 8, 1, 5, 0));
    });

    test('aYear is calendar year with offset', () {
      final now = DateAndTime(2026, 10, 13, 12, 0);

      final current = Period.aYear.toPeriod(now, startOfDay)!;
      expect(current.start, DateAndTime(2026, 1, 1, 5, 0));
      expect(current.end, DateAndTime(2027, 1, 1, 5, 0));

      final previous = Period.aYear.toPeriod(now, startOfDay, offset: -1)!;
      expect(previous.start, DateAndTime(2025, 1, 1, 5, 0));
      expect(previous.end, DateAndTime(2026, 1, 1, 5, 0));
    });

    test('all returns null', () {
      final now = DateAndTime(2026, 10, 13, 12, 0);
      expect(Period.all.toPeriod(now, startOfDay), isNull);
    });
  });

  group('Period.formatRange', () {
    testWidgets('aDay is a single date', (tester) async {
      final localizations = await _localizations(tester);
      final now = DateAndTime(2026, 10, 13, 12, 0);
      final period = Period.aDay.toPeriod(now, startOfDay)!;

      expect(
        Period.aDay.formatRange(localizations, period),
        localizations.formatCompactDate(period.start!),
      );
    });

    testWidgets('other periods use inclusive end', (tester) async {
      final localizations = await _localizations(tester);
      final now = DateAndTime(2026, 10, 13, 12, 0);
      final period = Period.aWeek.toPeriod(now, startOfDay)!;
      final inclusiveEnd = period.end!.subtract(const Duration(days: 1));

      expect(
        Period.aWeek.formatRange(localizations, period),
        '${localizations.formatCompactDate(period.start!)} – ${localizations.formatCompactDate(inclusiveEnd)}',
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
