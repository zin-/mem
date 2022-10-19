import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/views/atoms/date_and_time_view.dart';

import '../../_helpers.dart';

void main() {
  group('DateAndTimeText', () {
    group(': Appearance', () {
      testWidgets(
        ': date only',
        (widgetTester) async {
          final allDayDateAndTime = DateAndTime(2022, 10, 14);

          await runWidget(
            widgetTester,
            DateAndTimeText(allDayDateAndTime),
          );

          expect(dateAndTimeTextFinder, findsOneWidget);
          expect(find.byType(Text), findsOneWidget);

          expect(
            widgetTester
                .widget<Text>(find.descendant(
                  of: dateAndTimeTextFinder,
                  matching: find.byType(Text),
                ))
                .data,
            '10/14/2022', // in locale is en
          );
        },
        tags: TestSize.small,
      );

      testWidgets(
        ': date and time',
        (widgetTester) async {
          final dateAndTime = DateAndTime(2022, 10, 14, 13, 31);

          await runWidget(
            widgetTester,
            DateAndTimeText(dateAndTime),
          );

          expect(
            widgetTester
                .widget<Text>(find.descendant(
                  of: dateAndTimeTextFinder,
                  matching: find.byType(Text),
                ))
                .data,
            '10/14/2022 13:31', // in locale is en
          );
        },
        tags: TestSize.small,
      );

      testWidgets(
        ': 00:00',
        (widgetTester) async {
          final dateAndTime = DateAndTime(2022, 10, 14, 0, 0);

          await runWidget(
            widgetTester,
            DateAndTimeText(dateAndTime),
          );

          expect(
            widgetTester
                .widget<Text>(find.descendant(
                  of: dateAndTimeTextFinder,
                  matching: find.byType(Text),
                ))
                .data,
            '10/14/2022 00:00', // in locale is en
          );
        },
        tags: TestSize.small,
      );
    });
  });

  group('DateTextFormFieldV2', () {
    group(': Appearance', () {
      testWidgets(
        ': date is null',
        (widgetTester) async {
          const date = null;

          await runWidget(
            widgetTester,
            DateTextFormFieldV2(
              date,
              (pickedDate) => fail('should not be called'),
            ),
          );
          await widgetTester.pump();

          expect(
            widgetTester
                .widget<TextFormField>(find.byType(TextFormField))
                .initialValue,
            '',
          );
          expect(pickDateIconFinder, findsOneWidget);
        },
        tags: TestSize.small,
      );

      testWidgets(
        ': date is not null',
        (widgetTester) async {
          final date = DateTime(2022, 2, 29);

          await runWidget(
            widgetTester,
            DateTextFormFieldV2(
              date,
              (pickedDate) => fail('should not be called'),
            ),
          );
          await widgetTester.pump();

          expect(
            widgetTester
                .widget<TextFormField>(find.byType(TextFormField))
                .initialValue,
            '3/1/2022', // in locale is en
          );
        },
        tags: TestSize.small,
      );

      testWidgets(
        ': show date picker',
        (widgetTester) async {
          const date = null;

          await runWidget(
            widgetTester,
            DateTextFormFieldV2(
              date,
              (pickedDate) => fail('should not be called'),
            ),
          );
          await widgetTester.pump();

          await widgetTester.tap(pickDateIconFinder);
          await widgetTester.pump();

          expect(okFinder, findsOneWidget);
          expect(cancelFinder, findsOneWidget);
        },
        tags: TestSize.small,
      );
    });

    group(': Operation', () {
      group(': Pick date', () {
        testWidgets(
          ': now',
          (widgetTester) async {
            const date = null;

            await runWidget(
              widgetTester,
              DateTextFormFieldV2(
                date,
                (pickedDate) {
                  expect(pickedDate, isNotNull);

                  final now = DateTime.now();
                  expect(pickedDate?.year, now.year);
                  expect(pickedDate?.month, now.month);
                  expect(pickedDate?.day, now.day);
                  expect(pickedDate?.hour, 0);
                  expect(pickedDate?.minute, 0);
                  expect(pickedDate?.millisecond, 0);
                  expect(pickedDate?.microsecond, 0);
                },
              ),
            );
            await widgetTester.pump();

            await widgetTester.tap(pickDateIconFinder);
            await widgetTester.pump();

            await widgetTester.tap(okFinder);
          },
          tags: TestSize.small,
        );

        testWidgets(
          ': initial date is null and cancel',
          (widgetTester) async {
            const date = null;

            await runWidget(
              widgetTester,
              DateTextFormFieldV2(
                date,
                (pickedDate) => fail('should not be called'),
              ),
            );
            await widgetTester.pump();

            await widgetTester.tap(pickDateIconFinder);
            await widgetTester.pump();

            await widgetTester.tap(cancelFinder);
          },
          tags: TestSize.small,
        );

        testWidgets(
          ': initial date is not null and cancel',
          (widgetTester) async {
            final date = DateTime.now();

            await runWidget(
              widgetTester,
              DateTextFormFieldV2(
                date,
                (pickedDate) {
                  expect(pickedDate, null);
                },
              ),
            );
            await widgetTester.pump();

            await widgetTester.tap(pickDateIconFinder);
            await widgetTester.pump();

            await widgetTester.tap(cancelFinder);
          },
          tags: TestSize.small,
        );
      });
    });
  });
}

final dateAndTimeTextFinder = find.byType(DateAndTimeText);

final pickDateIconFinder = find.byIcon(Icons.calendar_month);
final okFinder = find.text('OK');
final cancelFinder = find.text('CANCEL');
