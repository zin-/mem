import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database_manager.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  DatabaseManager(onTest: true);

  testTodoScenario();
}

void testTodoScenario() => group(
      'Todo scenario',
      () {
        setUp(() async => await clearDatabase());

        group(
          'Todo scenario',
          () {
            testWidgets(
              ': done',
              (widgetTester) async {
                const savedMemName = 'saved mem name';
                const savedMemMemo = 'saved mem memo';
                await prepareSavedData(savedMemName, savedMemMemo);

                await runApplication(languageCode: 'en');
                await widgetTester.pumpAndSettle(defaultDuration);

                await widgetTester.tap(find.byType(Checkbox));
                await widgetTester.pumpAndSettle(defaultDuration);

                expect(find.text(savedMemName), findsNothing);

                await widgetTester.tap(memListFilterButton);
                await widgetTester.pumpAndSettle(defaultDuration);
                await widgetTester.tap(find.byType(Switch).at(3));
                await closeMemListFilter(widgetTester);

                expect(find.text(savedMemName), findsOneWidget);
              },
              tags: TestSize.medium,
            );
          },
        );
      },
    );
