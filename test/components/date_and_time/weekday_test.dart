import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/date_and_time/weekday.dart';

void main() {
  Future<MaterialLocalizations> pumpLocalizations(
    WidgetTester tester, {
    required Locale locale,
  }) async {
    late MaterialLocalizations localizations;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [locale],
        home: Builder(
          builder: (context) {
            localizations = MaterialLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return localizations;
  }

  testWidgets(
    'en starts on Sunday',
    (tester) async {
      final localizations =
          await pumpLocalizations(tester, locale: const Locale('en'));

      expect(
        weekdaysInLocalizedOrder(localizations),
        [
          DateTime.sunday,
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
        ],
      );
      expect(
        weekdayLabel(localizations, const Locale('en'), DateTime.monday),
        'Mon',
      );
      expect(
        weekdayLabel(localizations, const Locale('en'), DateTime.tuesday),
        'Tue',
      );
      expect(
        weekdayLabel(localizations, const Locale('en'), DateTime.thursday),
        'Thu',
      );
    },
  );

  testWidgets(
    'de starts on Monday',
    (tester) async {
      final localizations =
          await pumpLocalizations(tester, locale: const Locale('de'));

      expect(
        weekdaysInLocalizedOrder(localizations),
        [
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ],
      );
    },
  );

  testWidgets(
    'ja uses one-character weekdays',
    (tester) async {
      final localizations =
          await pumpLocalizations(tester, locale: const Locale('ja'));

      expect(
        weekdayLabel(localizations, const Locale('ja'), DateTime.monday),
        '月',
      );
    },
  );
}
