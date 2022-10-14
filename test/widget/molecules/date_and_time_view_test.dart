import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/views/molecules/date_and_time_view.dart';

import '../../_helpers.dart';

void main() {
  group('View', () {
    testWidgets(
      ': date only',
      (widgetTester) async {
        final date = DateTime(2022, 10, 14);
        const timeOfDay = null;

        await runWidget(
          widgetTester,
          DateAndTimeText(date, timeOfDay),
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
        final date = DateTime(2022, 10, 14);
        const timeOfDay = TimeOfDay(hour: 13, minute: 31);

        await runWidget(
          widgetTester,
          DateAndTimeText(date, timeOfDay),
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
  });
}

final dateAndTimeTextFinder = find.byType(DateAndTimeText);
final _textFinder = find.byType(Text);
