import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testTodoScenario();
}

void testTodoScenario() => group(': Todo scenario', () {
      const savedMemName = 'Todo scenario: saved mem name';

      setUp(() async {
        final memTable =
            (await DatabaseManager(onTest: true).open(app.databaseDefinition))
                .getTable(memTableDefinition.name);

        await memTable.insert({
          defMemName.name: savedMemName,
          createdAtColumnName: DateTime.now(),
        });
      });

      testWidgets(
        ': done.',
        (widgetTester) async {
          await app.main();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.byType(Checkbox));
          await widgetTester.pumpAndSettle();

          expect(find.text(savedMemName), findsNothing);

          await widgetTester.tap(memListFilterButton);
          await widgetTester.pumpAndSettle(defaultDuration);
          await widgetTester.tap(find.byType(Switch).at(3));
          await closeMemListFilter(widgetTester);

          expect(find.text(savedMemName), findsOneWidget);

          await widgetTester.tap(find.byType(Checkbox));
          await widgetTester.pumpAndSettle();

          expect(find.text(savedMemName), findsOneWidget);
        },
      );
    });
