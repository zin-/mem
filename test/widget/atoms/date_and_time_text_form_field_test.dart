import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/molecules/date_and_time_text_form_field.dart';
import 'package:mem/views/atoms/date_text_form_field.dart';
import 'package:mem/views/atoms/time_of_day_text_form_field.dart';

import '../../helpers.dart';

void main() {
  Logger(level: Level.verbose);

  Future pumpDateTimeTextField(
    WidgetTester widgetTester,
    DateTime? date,
    TimeOfDay? timeOfDay,
    Function(DateTime? pickedDate, TimeOfDay? pickedTimeOfDay)? onChanged,
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
            onChanged: onChanged ?? (date, timeOfDay) {},
          ),
        ),
      ),
    );
  }

  group('Show', () {
    testWidgets(
      'No date and time of day',
      (widgetTester) async {
        await pumpDateTimeTextField(widgetTester, null, null, null);

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
      tags: TestSize.small,
    );

    testWidgets(
      'With Date and no time of day',
      (widgetTester) async {
        final date = DateTime.now();

        await pumpDateTimeTextField(widgetTester, date, null, null);

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
      tags: TestSize.small,
    );

    testWidgets(
      'With date and time of day',
      (widgetTester) async {
        final date = DateTime.now();
        final timeOfDay = TimeOfDay.fromDateTime(date);

        await pumpDateTimeTextField(widgetTester, date, timeOfDay, null);

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
      tags: TestSize.small,
    );
  });

  group('onChanged', () {
    testWidgets(
      ': date',
      (widgetTester) async {
        await pumpDateTimeTextField(
          widgetTester,
          null,
          null,
          (pickedDate, pickedTimeOfDay) {
            expect(pickedTimeOfDay, isNull);
          },
        );

        await pickNowDate(widgetTester);
      },
      tags: TestSize.small,
    );

    testWidgets(
      ': timeOfDay',
      (widgetTester) async {
        await pumpDateTimeTextField(
          widgetTester,
          null,
          TimeOfDay.now(),
          (pickedDate, pickedTimeOfDay) {
            expect(pickedDate.runtimeType, DateTime);
          },
        );

        pickNowTimeOfDay(widgetTester);
      },
      tags: TestSize.small,
    );

    group(
      'all day',
      () {
        testWidgets(
          ': be false',
          (widgetTester) async {
            await pumpDateTimeTextField(
              widgetTester,
              null,
              null,
              (pickedDate, pickedTimeOfDay) {
                expect(pickedTimeOfDay.runtimeType, TimeOfDay);
              },
            );

            tapAllDaySwitch(widgetTester);
          },
          tags: TestSize.small,
        );

        testWidgets(
          ': be true',
          (widgetTester) async {
            await pumpDateTimeTextField(
              widgetTester,
              null,
              TimeOfDay.now(),
              (pickedDate, pickedTimeOfDay) {
                expect(pickedTimeOfDay, isNull);
              },
            );

            await tapAllDaySwitch(widgetTester);
          },
          tags: TestSize.small,
        );
      },
    );

    testWidgets(
      ': clear',
      (widgetTester) async {
        await pumpDateTimeTextField(
          widgetTester,
          DateTime.now(),
          TimeOfDay.now(),
          (pickedDate, pickedTimeOfDay) {
            expect(pickedDate, isNull);
            expect(pickedTimeOfDay, isNull);
          },
        );

        await tapClear(widgetTester);
      },
      tags: TestSize.small,
    );
  });
}

pickNowDate(WidgetTester widgetTester) async {
  await widgetTester.tap(find.descendant(
    of: find.byType(DateAndTimeTextFormField),
    matching: find.byIcon(Icons.calendar_month),
  ));
  await widgetTester.pump();

  await widgetTester.tap(find.text('OK'));
}

pickNowTimeOfDay(WidgetTester widgetTester) async {
  await widgetTester.tap(find.descendant(
    of: find.byType(DateAndTimeTextFormField),
    matching: find.byIcon(Icons.access_time_outlined),
  ));
  await widgetTester.pump();

  await widgetTester.tap(find.text('OK'));
}

tapAllDaySwitch(WidgetTester widgetTester) async {
  await widgetTester.tap(find.descendant(
    of: find.byType(DateAndTimeTextFormField),
    matching: find.byType(Switch),
  ));
  await widgetTester.pump();
}

tapClear(WidgetTester widgetTester) async {
  await widgetTester.tap(find.descendant(
    of: find.byType(DateAndTimeTextFormField),
    matching: find.byIcon(Icons.clear),
  ));
  await widgetTester.pump();
}
