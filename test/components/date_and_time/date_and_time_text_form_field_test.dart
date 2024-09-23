import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/date_and_time/date_and_time_text_form_field.dart';
import 'package:mem/components/date_and_time/date_view.dart';
import 'package:mem/components/date_and_time/time_of_day_view.dart';
import 'package:mem/date_and_time/date_and_time.dart';
import 'package:mem/date_and_time/date_and_time_period.dart';

import '../../helpers.dart';

void main() {
  Future<void> showTarget(
    WidgetTester widgetTester,
    DateAndTime? dateAndTime,
    void Function(DateAndTime? pickedDateAndTime) onChanged, {
    DateAndTimePeriod? selectableRange,
  }) async {
    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DateAndTimeTextFormField(
          dateAndTime,
          onChanged,
          selectableRange: selectableRange,
        ),
      ),
    ));
  }

  final dateTextFormFieldFinder = find.byType(DateTextFormField);
  final allDaySwitchFinder = find.byType(Switch);

  group('Show', () {
    final timeOfDayTextFormFieldFinder = find.byType(TimeOfDayTextFormField);
    final clearIconFinder = find.byIcon(Icons.clear);

    testWidgets(
      ': dateAndTime is null.',
      (widgetTester) async {
        const dateAndTime = null;

        await showTarget(
          widgetTester,
          dateAndTime,
          (pickedDateAndTime) {},
        );

        expect(dateTextFormFieldFinder, findsOneWidget);
        expect(timeOfDayTextFormFieldFinder, findsNothing);
        expect(allDaySwitchFinder, findsOneWidget);
        expect(clearIconFinder, findsNothing);

        expect(
          (widgetTester.widget(dateTextFormFieldFinder) as DateTextFormField)
              .date,
          null,
        );
        expect(
          (widgetTester.widget(allDaySwitchFinder) as Switch).value,
          true,
        );
      },
    );
    testWidgets(
      ': dateAndTime is all day.',
      (widgetTester) async {
        final dateAndTime = DateAndTime(2023, 5, 2);

        await showTarget(
          widgetTester,
          dateAndTime,
          (pickedDateAndTime) {},
        );

        expect(dateTextFormFieldFinder, findsOneWidget);
        expect(timeOfDayTextFormFieldFinder, findsNothing);
        expect(allDaySwitchFinder, findsOneWidget);
        expect(clearIconFinder, findsOneWidget);

        expect(
          (widgetTester.widget(dateTextFormFieldFinder) as DateTextFormField)
              .date,
          dateAndTime,
        );
        expect(
          (widgetTester.widget(allDaySwitchFinder) as Switch).value,
          true,
        );
      },
    );
    testWidgets(
      ': dateAndTime is not all day.',
      (widgetTester) async {
        final dateAndTime = DateAndTime(2023, 5, 2, 11, 34);

        await showTarget(
          widgetTester,
          dateAndTime,
          (pickedDateAndTime) {},
        );

        expect(dateTextFormFieldFinder, findsOneWidget);
        expect(timeOfDayTextFormFieldFinder, findsOneWidget);
        expect(allDaySwitchFinder, findsOneWidget);
        expect(clearIconFinder, findsOneWidget);

        expect(
          (widgetTester.widget(dateTextFormFieldFinder) as DateTextFormField)
              .date,
          dateAndTime,
        );
        expect(
          (widgetTester.widget(timeOfDayTextFormFieldFinder)
                  as TimeOfDayTextFormField)
              .timeOfDay,
          TimeOfDay.fromDateTime(dateAndTime),
        );
        expect(
          (widgetTester.widget(allDaySwitchFinder) as Switch).value,
          false,
        );
      },
    );
  });

  group('Action', () {
    group(': Pick date', () {
      testWidgets(
        ': cancel.',
        (widgetTester) async {
          var count = 0;

          const dateAndTime = null;

          await showTarget(
            widgetTester,
            dateAndTime,
            (pickedDateAndTime) {
              count++;
            },
          );

          await widgetTester.tap(find.byIcon(Icons.calendar_month));
          await widgetTester.pump();
          await widgetTester.tap(cancelTextFinder);

          expect(count, 0);
        },
      );

      testWidgets(
        ': pre value is null.',
        (widgetTester) async {
          var count = 0;

          final now = DateTime.now();

          const dateAndTime = null;
          const selectDate = 1;

          await showTarget(
            widgetTester,
            dateAndTime,
            (pickedDateAndTime) {
              expect(
                pickedDateAndTime,
                DateAndTime(
                  now.year,
                  now.month,
                  selectDate,
                ),
              );
              count++;
            },
          );

          await widgetTester.tap(find.byIcon(Icons.calendar_month));
          await widgetTester.pump();
          await widgetTester.tap(find.text('$selectDate'));
          await widgetTester.tap(find.text('OK'));

          expect(count, 1);
        },
      );
      testWidgets(
        ': pre value is all day.',
        (widgetTester) async {
          var count = 0;

          final now = DateTime.now();

          final dateAndTime = DateAndTime.now(allDay: true);
          const selectDate = 2;

          await showTarget(
            widgetTester,
            dateAndTime,
            (pickedDateAndTime) {
              expect(
                pickedDateAndTime,
                DateAndTime(
                  now.year,
                  now.month,
                  selectDate,
                ),
              );
              count++;
            },
          );

          await widgetTester.tap(find.byIcon(Icons.calendar_month));
          await widgetTester.pump();
          await widgetTester.tap(find.text('$selectDate'));
          await widgetTester.tap(find.text('OK'));

          expect(count, 1);
        },
      );
      testWidgets(
        ': pre value is not all day.',
        (widgetTester) async {
          var count = 0;

          final dateAndTime = DateAndTime.now(allDay: false);
          const selectDate = 3;

          await showTarget(
            widgetTester,
            dateAndTime,
            (pickedDateAndTime) {
              expect(
                pickedDateAndTime,
                DateAndTime(
                  dateAndTime.year,
                  dateAndTime.month,
                  selectDate,
                  dateAndTime.hour,
                  dateAndTime.minute,
                  dateAndTime.second,
                  dateAndTime.millisecond,
                  dateAndTime.microsecond,
                ),
              );
              count++;
            },
          );

          await widgetTester.tap(find.byIcon(Icons.calendar_month));
          await widgetTester.pump();
          await widgetTester.tap(find.text('$selectDate'));
          await widgetTester.tap(find.text('OK'));
          await widgetTester.pump();

          expect(count, 1);
        },
      );

      group(': can not select date is out of range', () {
        testWidgets(
          ': start.',
          (widgetTester) async {
            var count = 0;

            final dateTime = DateAndTime(2023, 5, 1);
            const canNotSelectDate = 1;
            const rangeEndDate = 2;

            await showTarget(
              widgetTester,
              dateTime,
              (pickedDateAndTime) {
                expect(
                  pickedDateAndTime,
                  DateAndTime(
                    dateTime.year,
                    dateTime.month,
                    rangeEndDate,
                  ),
                );
                count++;
              },
              selectableRange: DateAndTimePeriod(
                start: DateAndTime(
                  dateTime.year,
                  dateTime.month,
                  rangeEndDate,
                ),
              ),
            );

            await widgetTester.tap(find.byIcon(Icons.calendar_month));
            await widgetTester.pump();

            await widgetTester.tap(find.text('$canNotSelectDate'));
            await widgetTester.tap(find.text('OK'));
            await widgetTester.pump();

            expect(count, 1);
          },
        );
        testWidgets(
          ': end.',
          (widgetTester) async {
            var count = 0;

            final now = DateTime.now();
            const canNotSelectDate = 2;
            const rangeEndDate = 1;

            await showTarget(
              widgetTester,
              null,
              (pickedDateAndTime) {
                expect(
                  pickedDateAndTime,
                  DateAndTime(
                    now.year,
                    now.month,
                    rangeEndDate,
                  ),
                );
                count++;
              },
              selectableRange: DateAndTimePeriod(
                end: DateAndTime(
                  now.year,
                  now.month,
                  rangeEndDate,
                ),
              ),
            );

            await widgetTester.tap(find.byIcon(Icons.calendar_month));
            await widgetTester.pump();

            await widgetTester.tap(find.text('$canNotSelectDate'));
            await widgetTester.tap(find.text('OK'));
            await widgetTester.pump();

            expect(count, 1);
          },
        );
      });
    });

    group(': Switch all day', () {
      testWidgets(
        ': cancel.',
        (widgetTester) async {
          var count = 0;

          const dateAndTime = null;

          await showTarget(
            widgetTester,
            dateAndTime,
            (pickedDateAndTime) {
              count++;
            },
          );

          await widgetTester.tap(allDaySwitchFinder);
          await widgetTester.pump();

          await widgetTester.tap(cancelTextFinder);
          await widgetTester.pump();

          expect(count, 0);
        },
      );

      testWidgets(
        ': pre value is all day.',
        (widgetTester) async {
          var count = 0;

          final now = DateTime.now();
          final dateAndTime = DateAndTime.now(allDay: true);

          await showTarget(
            widgetTester,
            dateAndTime,
            (pickedDateAndTime) {
              expect(
                pickedDateAndTime,
                DateAndTime(
                  dateAndTime.year,
                  dateAndTime.month,
                  dateAndTime.day,
                  now.hour,
                  now.minute,
                ),
              );

              count++;
            },
          );

          await widgetTester.tap(allDaySwitchFinder);
          await widgetTester.pump();

          await widgetTester.tap(find.text('OK'));

          expect(count, 1);
        },
      );
      testWidgets(
        ': pre value is not all day.',
        (widgetTester) async {
          var count = 0;

          final dateAndTime = DateAndTime.now(allDay: false);

          await showTarget(
            widgetTester,
            dateAndTime,
            (pickedDateAndTime) {
              expect(
                pickedDateAndTime,
                DateAndTime(
                  dateAndTime.year,
                  dateAndTime.month,
                  dateAndTime.day,
                ),
              );

              count++;
            },
          );

          await widgetTester.tap(allDaySwitchFinder);
          await widgetTester.pump();

          expect(count, 1);
        },
      );
    });

    group(': Pick time', () {
      testWidgets(
        ': cancel.',
        (widgetTester) async {
          var count = 0;

          final dateAndTime = DateAndTime.now(allDay: false);

          await showTarget(
            widgetTester,
            dateAndTime,
            (pickedDateAndTime) {
              count++;
            },
          );

          await widgetTester.tap(find.byIcon(Icons.access_time_outlined));
          await widgetTester.pump();

          await widgetTester.tap(cancelTextFinder);
          await widgetTester.pump();

          expect(count, 0);
        },
      );

      testWidgets(
        ': pick.',
        (widgetTester) async {
          var count = 0;

          final dateAndTime = DateAndTime.now(allDay: false);

          await showTarget(
            widgetTester,
            dateAndTime,
            (pickedDateAndTime) {
              expect(
                pickedDateAndTime,
                DateAndTime(
                  dateAndTime.year,
                  dateAndTime.month,
                  dateAndTime.day,
                  dateAndTime.hour,
                  dateAndTime.minute,
                  dateAndTime.second,
                ),
              );

              count++;
            },
          );

          await widgetTester.tap(find.byIcon(Icons.access_time_outlined));
          await widgetTester.pump();

          await widgetTester.tap(find.text('OK'));
          await widgetTester.pump();

          expect(count, 1);
        },
      );
    });

    testWidgets(
      ': Clear.',
      (widgetTester) async {
        var count = 0;

        final dateAndTime = DateAndTime.now();

        await showTarget(
          widgetTester,
          dateAndTime,
          (pickedDateAndTime) {
            expect(pickedDateAndTime, null);

            count++;
          },
        );

        await widgetTester.tap(find.byIcon(Icons.clear));

        expect(count, 1);
      },
    );
  });
}
