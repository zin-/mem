import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/atoms/date_and_time_text_form_field.dart';
import 'package:mem/views/atoms/date_text_form_field.dart';
import 'package:mem/views/atoms/time_of_day_text_form_field.dart';

void main() {
  Logger(level: Level.verbose);

  Future pumpDateTimeTextField(
    WidgetTester widgetTester,
    DateTime? date,
    Function(DateTime? pickedDate)? onDateChanged,
    TimeOfDay? timeOfDay,
    Function(TimeOfDay? pickedtimeOfDay)? onTimeOfDayChanged,
  ) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        onGenerateTitle: (context) => L10n(context).test(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: DateAndTimeTextFormField(
              date: date,
              onDateChanged: onDateChanged ?? (pickedDate) {},
              timeOfDay: timeOfDay,
              onTimeOfDayChanged: onTimeOfDayChanged ?? (pickedTimeOfDay) {}),
        ),
      ),
    );
  }

  group('Show', () {
    testWidgets(
      'No date and time of day',
      (widgetTester) async {
        await pumpDateTimeTextField(widgetTester, null, null, null, null);

        expect(find.byType(DateTextFormField), findsOneWidget);
        expect(find.byType(TimeOfDayTextFormField), findsNothing);
        expect(find.byType(Switch), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsNothing);

        expect(
          widgetTester
              .widget<DateTextFormField>(find.byType(DateTextFormField))
              .date,
          isNull,
        );
        expect(
          widgetTester.widget<Switch>(find.byType(Switch)).value,
          true,
        );
      },
      tags: 'Small',
    );

    testWidgets(
      'No time of day',
      (widgetTester) async {
        final date = DateTime.now();

        await pumpDateTimeTextField(widgetTester, date, null, null, null);

        expect(find.byType(DateTextFormField), findsOneWidget);
        expect(find.byType(TimeOfDayTextFormField), findsNothing);
        expect(find.byType(Switch), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsOneWidget);

        expect(
          widgetTester
              .widget<DateTextFormField>(find.byType(DateTextFormField))
              .date,
          date,
        );
        expect(
          widgetTester.widget<Switch>(find.byType(Switch)).value,
          true,
        );
      },
      tags: 'Small',
    );

    testWidgets(
      'With date and time of day',
      (widgetTester) async {
        final date = DateTime.now();
        final timeOfDay = TimeOfDay.fromDateTime(date);

        await pumpDateTimeTextField(widgetTester, date, null, timeOfDay, null);

        expect(find.byType(DateTextFormField), findsOneWidget);
        expect(find.byType(TimeOfDayTextFormField), findsOneWidget);
        expect(find.byType(Switch), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsOneWidget);

        expect(
          widgetTester
              .widget<DateTextFormField>(find.byType(DateTextFormField))
              .date,
          date,
        );
        expect(
          widgetTester
              .widget<TimeOfDayTextFormField>(
                  find.byType(TimeOfDayTextFormField))
              .timeOfDay,
          timeOfDay,
        );
        expect(
          widgetTester.widget<Switch>(find.byType(Switch)).value,
          false,
        );
      },
      tags: 'Small',
    );
  });

  testWidgets(
    'Edit',
    (widgetTester) async {},
    tags: 'Small',
  );
}
