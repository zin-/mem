import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';
import 'package:mem/repositories/mem_item_repository.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testTodoScenario();
}

const scenarioName = 'Todo scenario';

void testTodoScenario() => group(': $scenarioName', () {
      const savedMemName = '$scenarioName: saved mem name';

      const undoneMemName = '$scenarioName: undone';
      const doneMemName = '$scenarioName: done';

      late final Database db;

      setUpAll(() async {
        // TODO remove
        LogServiceV2.initialize(Level.verbose);

        db = await DatabaseManager(onTest: true).open(app.databaseDefinition);
      });
      setUp(() async {
        final memTable = db.getTable(memTableDefinition.name);

        await memTable.insert({
          defMemName.name: savedMemName,
          createdAtColumnName: DateTime.now(),
        });
        await memTable.insert({
          defMemName.name: undoneMemName,
          createdAtColumnName: DateTime.now(),
          defMemDoneAt.name: null,
        });
        await memTable.insert({
          defMemName.name: doneMemName,
          createdAtColumnName: DateTime.now(),
          defMemDoneAt.name: DateTime.now(),
        });
      });
      tearDown(() async {
        final memItemTable = db.getTable(memItemTableDefinition.name);
        await memItemTable.delete();

        final memTable = db.getTable(memTableDefinition.name);
        await memTable.delete();
      });
      tearDownAll(() async {
        await DatabaseManager(onTest: true).delete(app.databaseDefinition.name);

        // TODO remove
        LogServiceV2.initialize(Level.error);
      });

      group(': done & undone', () {
        testWidgets(': on detail.', (widgetTester) async {
          await app.main();
          await widgetTester.pumpAndSettle();

          expect(find.text(undoneMemName), findsOneWidget);
          expect(find.text(doneMemName), findsNothing);
          await widgetTester.tap(find.text(savedMemName));
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byType(Checkbox));
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle();
          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();

          expect(find.text(savedMemName), findsNothing);
          expect(find.text(undoneMemName), findsOneWidget);
          expect(find.text(doneMemName), findsNothing);
          await widgetTester.tap(memListFilterButton);
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byType(Switch).at(3));
          await closeMemListFilter(widgetTester);
          await widgetTester.pumpAndSettle();

          expect(find.text(savedMemName), findsOneWidget);
          expect(find.text(undoneMemName), findsOneWidget);
          expect(find.text(doneMemName), findsOneWidget);
          await widgetTester.tap(find.text(savedMemName));
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
          expect(find.text(savedMemName), findsNothing);
          expect(find.text(undoneMemName), findsNothing);
          expect(find.text(doneMemName), findsOneWidget);
        });

        testWidgets(
          ': on list.',
          (widgetTester) async {
            await app.main();
            await widgetTester.pumpAndSettle();

            expect(find.text(savedMemName), findsOneWidget);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsNothing);
            await widgetTester.tap(find.byType(Checkbox).at(0));
            await widgetTester.pumpAndSettle();

            expect(find.text(savedMemName), findsNothing);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsNothing);
            await widgetTester.tap(memListFilterButton);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byType(Switch).at(2));
            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle();

            expect(find.text(savedMemName), findsOneWidget);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsOneWidget);
            await widgetTester.tap(find.byType(Checkbox).at(1));
            await widgetTester.pumpAndSettle();

            expect(find.text(savedMemName), findsOneWidget);
            expect(find.text(undoneMemName), findsOneWidget);
            expect(find.text(doneMemName), findsOneWidget);
            await widgetTester.tap(memListFilterButton);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byType(Switch).at(3));
            await closeMemListFilter(widgetTester);
            await widgetTester.pumpAndSettle();

            expect(find.text(savedMemName), findsNothing);
            expect(find.text(undoneMemName), findsNothing);
            expect(find.text(doneMemName), findsOneWidget);
          },
        );
      });
    });
