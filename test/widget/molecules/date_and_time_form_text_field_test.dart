import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/views/_atoms/date_and_time_view.dart';
import 'package:mem/views/_molecules/date_and_time_text_form_field.dart';

import '../../_helpers.dart';
import '../atoms/date_and_time_view_test.dart';

void main() {
  group('Appearance', () {
    testWidgets(
      ': date and time is null',
      (widgetTester) async {
        const dateAndTime = null;

        await runWidget(
          widgetTester,
          DateAndTimeTextFormField(
            dateAndTime,
            (pickedDateAndTime) => fail('should not be called'),
          ),
        );

        expect(dateTextFormFieldFinder, findsOneWidget);
        expect(timeOfDayTextFormFieldFinder, findsNothing);
        expect(allDaySwitchFinder, findsNothing);
        expect(clearButtonFinder, findsNothing);
      },
      tags: TestSize.small,
    );

    testWidgets(
      ': all day',
      (widgetTester) async {
        final dateAndTime = DateAndTime.now(allDay: true);

        await runWidget(
          widgetTester,
          DateAndTimeTextFormField(
            dateAndTime,
            (pickedDateAndTime) => fail('should not be called'),
          ),
        );

        expect(dateTextFormFieldFinder, findsOneWidget);
        expect(timeOfDayTextFormFieldFinder, findsNothing);
        expect(allDaySwitchFinder, findsOneWidget);
        expect(clearButtonFinder, findsOneWidget);

        expect(widgetTester.widget<Switch>(allDaySwitchFinder).value, true);
      },
      tags: TestSize.small,
    );

    testWidgets(
      ': is not all day',
      (widgetTester) async {
        final dateAndTime = DateAndTime.now(allDay: false);

        await runWidget(
          widgetTester,
          DateAndTimeTextFormField(
            dateAndTime,
            (pickedDateAndTime) => fail('should not be called'),
          ),
        );

        expect(dateTextFormFieldFinder, findsOneWidget);
        expect(timeOfDayTextFormFieldFinder, findsOneWidget);
        expect(allDaySwitchFinder, findsOneWidget);
        expect(clearButtonFinder, findsOneWidget);

        expect(widgetTester.widget<Switch>(allDaySwitchFinder).value, false);
      },
      tags: TestSize.small,
    );
  });

  group('Operation', () {
    testWidgets(
      ': pick date',
      (widgetTester) async {
        await runWidget(
          widgetTester,
          DateAndTimeTextFormField(
            null,
            (pickedDateAndTime) {
              expect(pickedDateAndTime?.isAllDay, true);

              final now = DateTime.now();
              expect(pickedDateAndTime?.year, now.year);
              expect(pickedDateAndTime?.month, now.month);
              expect(pickedDateAndTime?.day, now.day);
            },
          ),
        );

        await widgetTester.tap(pickDateIconFinder);
        await widgetTester.pump();
        await widgetTester.tap(okFinder);
      },
    );

    testWidgets(
      ': pick date with time',
      (widgetTester) async {
        final dateAndTime = DateAndTime.now(allDay: false);

        await runWidget(
          widgetTester,
          DateAndTimeTextFormField(
            dateAndTime,
            (pickedDateAndTime) {
              expect(pickedDateAndTime?.isAllDay, dateAndTime.isAllDay);

              final now = DateTime.now();
              expect(pickedDateAndTime?.year, now.year);
              expect(pickedDateAndTime?.month, now.month);
              expect(pickedDateAndTime?.day, now.day);
            },
          ),
        );

        await widgetTester.tap(pickDateIconFinder);
        await widgetTester.pump();
        await widgetTester.tap(okFinder);
      },
    );

    testWidgets(
      ': pick time',
      (widgetTester) async {
        final dateAndTime = DateAndTime.now(allDay: false);

        await runWidget(
          widgetTester,
          DateAndTimeTextFormField(
            dateAndTime,
            (pickedDateAndTime) {
              expect(pickedDateAndTime?.isAllDay, false);

              final now = TimeOfDay.now();
              expect(pickedDateAndTime?.hour, now.hour);
              expect(pickedDateAndTime?.minute, now.minute);
            },
          ),
        );

        await widgetTester.tap(pickTimeIconFinder);
        await widgetTester.pump();
        await widgetTester.tap(okFinder);
      },
    );

    group(': All day', () {
      testWidgets(
        ': into not all day',
        (widgetTester) async {
          final dateAndTime = DateAndTime.now(allDay: true);

          await runWidget(
            widgetTester,
            DateAndTimeTextFormField(
              dateAndTime,
              (pickedDateAndTime) {
                expect(pickedDateAndTime?.isAllDay, false);
              },
            ),
          );

          await widgetTester.tap(allDaySwitchFinder);
          await widgetTester.pump();
        },
        tags: TestSize.small,
      );

      testWidgets(
        ': into all day',
        (widgetTester) async {
          final dateAndTime = DateAndTime.now(allDay: false);

          await runWidget(
            widgetTester,
            DateAndTimeTextFormField(
              dateAndTime,
              (pickedDateAndTime) {
                expect(pickedDateAndTime?.isAllDay, true);
              },
            ),
          );

          await widgetTester.tap(allDaySwitchFinder);
          await widgetTester.pump();
        },
        tags: TestSize.small,
      );
    });

    testWidgets(
      ': clear',
      (widgetTester) async {
        final dateAndTime = DateAndTime.now(allDay: true);

        await runWidget(
          widgetTester,
          DateAndTimeTextFormField(
            dateAndTime,
            (pickedDateAndTime) {
              expect(pickedDateAndTime, null);
            },
          ),
        );

        await widgetTester.tap(clearButtonFinder);
      },
      tags: TestSize.small,
    );
  });
}

final dateTextFormFieldFinder = find.descendant(
  of: find.byType(DateAndTimeTextFormField),
  matching: find.byType(DateTextFormField),
);
final timeOfDayTextFormFieldFinder = find.descendant(
  of: find.byType(DateAndTimeTextFormField),
  matching: find.byType(TimeOfDayTextFormField),
);
final allDaySwitchFinder = find.descendant(
  of: find.byType(DateAndTimeTextFormField),
  matching: find.byType(Switch),
);
final clearButtonFinder = find.descendant(
  of: find.byType(DateAndTimeTextFormField),
  matching: find.byIcon(Icons.clear),
);
