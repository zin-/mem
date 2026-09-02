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
        weekdayLabel(localizations, DateTime.monday),
        localizations.narrowWeekdays[DateTime.monday % 7],
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
}
