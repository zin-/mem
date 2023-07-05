import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/date_and_time/time_of_day_view.dart';
import 'package:mem/components/l10n.dart';

void main() {
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

        await pickNowTimeOfDay(widgetTester, cancelButton);
      },
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

        await pickNowTimeOfDay(widgetTester, okButton);
      },
    );
  });
}

Finder okButton = find.text('OK');
Finder cancelButton = find.text('CANCEL');

Future<void> showTimeOfDayPicker(WidgetTester widgetTester) async {
  await widgetTester.tap(find.descendant(
    of: find.byType(TimeOfDayTextFormField),
    matching: find.byIcon(Icons.access_time_outlined),
  ));
  await widgetTester.pump();
}

Future<void> pickNowTimeOfDay(
  WidgetTester widgetTester,
  Finder tapTarget,
) async {
  await showTimeOfDayPicker(widgetTester);

  await widgetTester.tap(tapTarget);
}
