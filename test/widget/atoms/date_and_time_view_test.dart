import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/domains/date_and_time.dart';
import 'package:mem/views/atoms/date_and_time_view.dart';

import '../../_helpers.dart';

void main() {
  group('DateAndTimeText', () {
    testWidgets(
      ': date only',
      (widgetTester) async {
        final allDayDateAndTime = DateAndTime(2022, 10, 14);

        await runWidget(
          widgetTester,
          DateAndTimeText(allDayDateAndTime),
        );

        expect(dateAndTimeTextFinder, findsOneWidget);
        expect(_textFinder, findsOneWidget);

        expect(
          widgetTester
              .widget<Text>(find.descendant(
                of: dateAndTimeTextFinder,
                matching: _textFinder,
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

        expect(dateAndTimeTextFinder, findsOneWidget);
        expect(_textFinder, findsOneWidget);

        expect(
          widgetTester
              .widget<Text>(find.descendant(
                of: dateAndTimeTextFinder,
                matching: _textFinder,
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

        expect(dateAndTimeTextFinder, findsOneWidget);
        expect(_textFinder, findsOneWidget);

        expect(
          widgetTester
              .widget<Text>(find.descendant(
                of: dateAndTimeTextFinder,
                matching: _textFinder,
              ))
              .data,
          '10/14/2022 00:00', // in locale is en
        );
      },
      tags: TestSize.small,
    );
  });

  group('DateTextFormField', () {
    group('Appearance', () {
      testWidgets(
        ': input null',
        (widgetTester) async {
          await runWidget(
            widgetTester,
            DateTextFormFieldV2(
              date: null, /*onChanged: (pickedDate) {}*/
            ),
          );
          await widgetTester.pump();

          expect(
            widgetTester
                .widget<TextFormField>(find.byType(TextFormField))
                .initialValue,
            '',
          );
        },
        tags: TestSize.small,
      );
    });
  });
}

final dateAndTimeTextFinder = find.byType(DateAndTimeText);
final _textFinder = find.byType(Text);
