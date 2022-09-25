import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/atoms/date_and_time_text_form_field.dart';

void main() {
  Logger(level: Level.verbose);

  Future pumpDateTimeTextField(
    WidgetTester widgetTester,
    DateTime? date,
    TimeOfDay? timeOfDay,
  ) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        onGenerateTitle: (context) => L10n(context).test(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: DateAndTimeTextFormField(
            date: date,
            timeOfDay: timeOfDay,
          ),
        ),
      ),
    );
  }

  group('Show', () {
    testWidgets(
      'No date and time',
      (widgetTester) async {
        await pumpDateTimeTextField(widgetTester, null, null);

        expect(widgetTester.widgetList(find.byType(TextFormField)).length, 1);
        expect(widgetTester.widgetList(find.byType(Switch)).length, 1);
        expect(widgetTester.widgetList(find.byType(IconButton)).length, 0);

        expect(
          widgetTester
              .widget<TextFormField>(find.byType(TextFormField))
              .initialValue,
          '',
        );
        expect(
          widgetTester.widget<Switch>(find.byType(Switch)).value,
          true,
        );
      },
      tags: 'Small',
    );
  });
}
