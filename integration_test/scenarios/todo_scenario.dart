import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/database/definition.dart';

import '../_helpers.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testTodoScenario();
}

const scenarioName = 'Todo scenario';

void testTodoScenario() => group(': $scenarioName', () {
      const insertedMemName = '$scenarioName - mem name - inserted';

      const undoneMemName = '$scenarioName - mem name - inserted - undone';
      const doneMemName = '$scenarioName - mem name - inserted - done';

      late final Database db;

      setUpAll(() async {
        db = await DatabaseManager(onTest: true).open(databaseDefinition);
      });
      setUp(() async {
        await resetDatabase(db);

        final memTable = db.getTable(memTableDefinition.name);
        await memTable.insert({
          defMemName.name: insertedMemName,
          createdAtColDef.name: DateTime.now(),
        });
        await memTable.insert({
          defMemName.name: undoneMemName,
          createdAtColDef.name: DateTime.now(),
          defMemDoneAt.name: null,
        });
        await memTable.insert({
          defMemName.name: doneMemName,
          createdAtColDef.name: DateTime.now(),
          defMemDoneAt.name: DateTime.now(),
        });
      });

      group(': done & undone', () {
        testWidgets(': MemDetail.', (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();

          expect(find.text(undoneMemName), findsOneWidget);
          expect(find.text(doneMemName), findsNothing);
          await widgetTester.tap(find.text(insertedMemName));
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byType(Checkbox));
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle();
          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();

          expect(find.text(insertedMemName), findsNothing);
          expect(find.text(undoneMemName), findsOneWidget);
          expect(find.text(doneMemName), findsNothing);
          await widgetTester.tap(memListFilterButton);
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byType(Switch).at(3));
          await closeMemListFilter(widgetTester);
          await widgetTester.pumpAndSettle();

          expect(find.text(insertedMemName), findsOneWidget);
          expect(find.text(undoneMemName), findsOneWidget);
          expect(find.text(doneMemName), findsOneWidget);
          await widgetTester.tap(find.text(insertedMemName));
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byType(Checkbox));
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle();
          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(memListFilterButton);
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byType(Switch).at(2));
          await closeMemListFilter(widgetTester);
          await widgetTester.pumpAndSettle();
          expect(find.text(insertedMemName), findsNothing);
          expect(find.text(undoneMemName), findsNothing);
          expect(find.text(doneMemName), findsOneWidget);
        });

        testWidgets(
          ': MemList.',
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            expect(find.text(insertedMemName), findsOneWidget);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsNothing);
            await widgetTester.tap(find.byType(Checkbox).at(0));
            await widgetTester.pumpAndSettle();

            expect(find.text(insertedMemName), findsNothing);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsNothing);
            await widgetTester.tap(memListFilterButton);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byType(Switch).at(2));
            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle();

            expect(find.text(insertedMemName), findsOneWidget);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsOneWidget);
            await widgetTester.tap(find.byType(Checkbox).at(1));
            await widgetTester.pumpAndSettle();

            expect(find.text(insertedMemName), findsOneWidget);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsOneWidget);
            await widgetTester.tap(memListFilterButton);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byType(Switch).at(3));
            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle();

            expect(find.text(insertedMemName), findsNothing);
            expect(find.text(undoneMemName), findsNothing);
            expect(find.text(doneMemName), findsOneWidget);
          },
        );
      });
    });
