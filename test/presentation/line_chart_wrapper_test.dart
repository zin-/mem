import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/features/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/l10n/l10n.dart';

void main() {
  testWidgets(
    'formats inner axis dates with month-day and day-of-month',
    (tester) async {
      final acts = List.generate(
        27,
        (index) {
          final date = DateAndTime.from(
            DateTime(2024, 12, 25).add(Duration(days: index)),
          );
          return FinishedAct(1, date, date);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          onGenerateTitle: (context) => buildL10n(context).test,
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: LineChartWrapper(
                ActsSummary(acts, AggregationType.count),
                (value) => value.toInt().toString(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(LineChartWrapper)),
      );

      expect(
        find.text(localizations.formatShortMonthDay(DateTime(2025, 1, 1))),
        findsOneWidget,
      );
      expect(find.text('10'), findsOneWidget);
    },
  );
}
