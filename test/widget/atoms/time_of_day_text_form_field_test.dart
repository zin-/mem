import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/atoms/time_of_day_text_form_field.dart';

import '../../_helpers.dart';

void main() {
  Logger(level: Level.verbose);

  Future pumpTimeOfDayTextFormField(
    WidgetTester widgetTester,
    TimeOfDay? timeOfDay,
    Function(TimeOfDay? pickedDate)? onChanged,
  ) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        onGenerateTitle: (context) => L10n(context).test(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: TimeOfDayTextFormField(
            timeOfDay: timeOfDay,
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
        await pumpTimeOfDayTextFormField(widgetTester, null, null);

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
        final timeOfDay = TimeOfDay.now();

        await pumpTimeOfDayTextFormField(widgetTester, timeOfDay, null);

        expect(widgetTester.widgetList(find.byType(TextFormField)).length, 1);

        final BuildContext context =
            widgetTester.element(find.byType(TimeOfDayTextFormField));
        expect(
          widgetTester
              .widget<TextFormField>(find.byType(TextFormField))
              .initialValue,
          timeOfDay.format(context),
        );
      },
      tags: TestSize.small,
    );
  });

  group('Pick', () {
    testWidgets(
      ': cancel',
      (widgetTester) async {
        await pumpTimeOfDayTextFormField(
          widgetTester,
          null,
          (pickedTimeOfDay) {
            expect(pickedTimeOfDay, isNull);
          },
        );

        await widgetTester.tap(find.byIcon(Icons.access_time_outlined));
        await widgetTester.pump();

        await widgetTester.tap(find.text('CANCEL'));
      },
      tags: TestSize.small,
    );

    testWidgets(
      ': pick',
      (widgetTester) async {
        await pumpTimeOfDayTextFormField(
          widgetTester,
          null,
          (pickedTimeOfDay) {
            expect(pickedTimeOfDay, isNotNull);
          },
        );

        await widgetTester.tap(find.byIcon(Icons.access_time_outlined));
        await widgetTester.pump();

        await widgetTester.tap(find.text('OK'));
      },
      tags: TestSize.small,
    );
  });
}
