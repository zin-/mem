import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/component/view/date_and_time/date_and_time_period_view.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';

import '../helpers.dart';

void main() {
  testWidgets(
    'Select out of selected range.',
    (widgetTester) async {
      var count = 0;

      final now = DateTime.now();
      final selected = DateAndTimePeriod(
        start: DateAndTime(now.year, now.month, 2),
      );

      await runTestWidget(
        widgetTester,
        DateAndTimePeriodTextFormFields(
          selected,
          (pickedStart) {
            expect(
              pickedStart.toString(),
              DateAndTime(now.year, now.month, 1).toString(),
            );
            count++;
          },
          (pickedStart) => null,
        ),
      );

      await widgetTester.tap(find.byIcon(Icons.calendar_month).at(0));
      await widgetTester.pump();

      await widgetTester.tap(find.text('1'));
      await widgetTester.tap(find.text('OK'));
      await widgetTester.pump();

      expect(count, 1);
    },
  );
}
