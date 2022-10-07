import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/atoms/date_text_form_field.dart';

import '../../_helpers.dart';

void main() {
  Logger(level: Level.verbose);

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
      tags: TestSize.small,
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
      tags: TestSize.small,
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
      tags: TestSize.small,
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
      tags: TestSize.small,
    );
  });
}
