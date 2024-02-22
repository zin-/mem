import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mem/components/date_and_time/date_view.dart';
import 'package:mem/components/l10n.dart';

import '../../helpers.dart';

void main() {
  Future pumpDateTextFormField(
    WidgetTester widgetTester,
    DateTime? date,
    Function(DateTime? pickedDate)? onChanged,
  ) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateTitle: (context) => buildL10n(context).test,
        home: Scaffold(
          body: DateTextFormField(
            date,
            onChanged ?? (pickedDate) {},
          ),
        ),
      ),
    );
  }

  group('Show', () {
    testWidgets(
      ': input null',
      (widgetTester) async {
        await pumpDateTextFormField(widgetTester, null, null);

        expect(widgetTester.widgetList(find.byType(TextFormField)).length, 1);

        expect(
          widgetTester
              .widget<TextFormField>(find.byType(TextFormField))
              .initialValue,
          '',
        );
      },
    );

    testWidgets(
      ': input now',
      (widgetTester) async {
        final date = DateTime.now();

        await pumpDateTextFormField(widgetTester, date, null);

        expect(widgetTester.widgetList(find.byType(TextFormField)).length, 1);

        expect(
          widgetTester
              .widget<TextFormField>(find.byType(TextFormField))
              .initialValue,
          DateFormat.yMd().format(date),
        );
      },
    );
  });

  group('Pick', () {
    testWidgets(
      ': cancel',
      (widgetTester) async {
        await pumpDateTextFormField(
          widgetTester,
          null,
          (pickedDate) {
            expect(pickedDate, isNull);
          },
        );

        await widgetTester.tap(find.byIcon(Icons.calendar_month));
        await widgetTester.pump();

        await widgetTester.tap(cancelTextFinder);
      },
    );

    testWidgets(
      ': pick',
      (widgetTester) async {
        await pumpDateTextFormField(
          widgetTester,
          null,
          (pickedDate) {
            expect(pickedDate, isNotNull);
          },
        );

        await widgetTester.tap(find.byIcon(Icons.calendar_month));
        await widgetTester.pump();

        await widgetTester.tap(find.text('OK'));
      },
    );
  });
}
