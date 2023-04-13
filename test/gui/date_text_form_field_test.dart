import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mem/gui/date_text_form_field.dart';
import 'package:mem/gui/l10n.dart';

void main() {
  Future pumpDateTextFormField(
    WidgetTester widgetTester,
    DateTime? date,
    Function(DateTime? pickedDate)? onChanged,
  ) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        onGenerateTitle: (context) => L10n(context).test(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: DateTextFormField(
            date: date,
            onChanged: onChanged ?? (pickedDate) {},
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

        await widgetTester.tap(find.text('CANCEL'));
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
