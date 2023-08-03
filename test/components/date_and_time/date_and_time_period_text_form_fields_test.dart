import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/date_and_time/date_and_time_period_view.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';

import '../../helpers.dart';
import '../helpers.dart';

void main() {
  final now = DateTime.now();

  for (final testCase in [
    TestCase(
      'pick start',
      DateAndTimePeriod(start: DateAndTime.from(now)),
      (input) => null,
    ),
    TestCase(
      'pick end',
      DateAndTimePeriod(end: DateAndTime.from(now)),
      (input) => null,
    ),
  ]) {
    testWidgets(
      'Change null: ${testCase.name}.',
      (widgetTester) async {
        var count = 0;

        await runTestWidget(
          widgetTester,
          DateAndTimePeriodTextFormFields(
            testCase.input,
            (picked) {
              expect(picked, null);
              count++;
            },
          ),
        );

        await widgetTester.tap(find.byIcon(Icons.clear));
        await widgetTester.pump();

        expect(count, 1);
      },
    );
  }
}
