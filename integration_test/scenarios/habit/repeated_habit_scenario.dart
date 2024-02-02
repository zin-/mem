import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/mems/detail/notifications_view.dart';

import '../helpers.dart';

void main() {
  testRepeatedHabitScenario();
}

const _scenarioName = 'Repeated habit scenario';

void testRepeatedHabitScenario() => group(
      ": $_scenarioName",
      () {
        testWidgets(
          ": show on new.",
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(newMemFabFinder);
            await widgetTester.pumpAndSettle();

            expect(
              widgetTester
                  .widget<TextFormField>(
                    find.descendant(
                        of: find.byKey(keyMemRepeatedNotification),
                        matching: find.byType(TextFormField)),
                  )
                  .initialValue,
              isEmpty,
            );
          },
        );
      },
    );
