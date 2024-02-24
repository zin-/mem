import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/components/mem/mem_name.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/mems/detail/fab.dart';
import 'package:mem/mems/detail/mem_items_view.dart';
import 'package:mem/mems/detail/app_bar/remove_mem_action.dart';
import 'package:mem/mems/transitions.dart';
import 'package:mem/values/durations.dart';

import '../helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testMemoDetailScenario();
}

const _scenarioName = "Memo detail scenario";

void testMemoDetailScenario() => group(
      " $_scenarioName",
      () {
        late final DatabaseAccessor dbA;
        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });

        const insertedMemName = "$_scenarioName - inserted - mem - name";
        const insertedMemMemo = "$_scenarioName - inserted - mem - memo";
        late int insertedMemId;

        setUp(() async {
          await clearAllTestDatabaseRows(databaseDefinition);

          insertedMemId = await dbA.insert(
            defTableMems,
            {
              defColMemsName.name: insertedMemName,
              defColCreatedAt.name: zeroDate,
            },
          );
          await dbA.insert(
            defTableMemItems,
            {
              defFkMemItemsMemId.name: insertedMemId,
              defColMemItemsType.name: MemItemType.memo.name,
              defColMemItemsValue.name: insertedMemMemo,
              defColCreatedAt.name: zeroDate,
            },
          );
        });

        group(
          ": Save",
          () {
            testWidgets(
              ": create.",
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(newMemFabFinder);
                await widgetTester.pumpAndSettle();

                const enteringMemName =
                    "$_scenarioName: Save: create - entering - mem - name";
                const enteringMemMemo =
                    "$_scenarioName: Save: create - entering - mem - memo";
                await widgetTester.enterText(
                    find.byKey(keyMemName), enteringMemName);
                await widgetTester.enterText(
                    find.byKey(keyMemMemo), enteringMemMemo);
                await widgetTester.tap(find.byKey(keySaveMemFab));
                await widgetTester.pumpAndSettle();

                expect(find.text(l10n.saveMemSuccessMessage(enteringMemName)),
                    findsOneWidget);
                final getCreatedMem =
                    Equals(defColMemsName.name, enteringMemName);
                final mems = await dbA.select(defTableMems,
                    where: getCreatedMem.where(),
                    whereArgs: getCreatedMem.whereArgs());
                expect(mems.length, 1);
                final getCreatedMemItem = And([
                  Equals(defFkMemItemsMemId.name, mems[0][defPkId.name]),
                  Equals(defColMemItemsType.name, MemItemType.memo.name),
                  Equals(defColMemItemsValue.name, enteringMemMemo)
                ]);
                final memItems = await dbA.select(defTableMemItems,
                    where: getCreatedMemItem.where(),
                    whereArgs: getCreatedMemItem.whereArgs());
                expect(memItems.length, 1);

                await widgetTester.pageBack();
                await widgetTester.pumpAndSettle(defaultTransitionDuration);
                expect(find.text(enteringMemName), findsOneWidget);
                expect(find.text(enteringMemMemo), findsNothing);
              },
            );

            testWidgets(
              ": twice on create.",
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(newMemFabFinder);
                await widgetTester.pumpAndSettle();
                const enteringMemName =
                    "$_scenarioName: Save: twice on create - entering - mem - name";
                const enteringMemMemo =
                    "$_scenarioName: Save: twice on create - entering - mem - memo";
                await widgetTester.enterText(
                    find.byKey(keyMemName), enteringMemName);
                await widgetTester.enterText(
                    find.byKey(keyMemMemo), enteringMemMemo);
                await widgetTester.tap(find.byKey(keySaveMemFab));
                await widgetTester.pumpAndSettle();

                const enteringMemMemo2 = "$enteringMemMemo - 2";
                await widgetTester.enterText(
                    find.byKey(keyMemMemo), enteringMemMemo2);
                await widgetTester.tap(find.byKey(keySaveMemFab));

                final getCreatedMem =
                    Equals(defColMemsName.name, enteringMemName);
                final mems = await dbA.select(defTableMems,
                    where: getCreatedMem.where(),
                    whereArgs: getCreatedMem.whereArgs());
                expect(mems.length, 1);
                final getCreatedMemItem = And([
                  Equals(defFkMemItemsMemId.name, mems[0][defPkId.name]),
                  Equals(defColMemItemsType.name, MemItemType.memo.name),
                ]);
                final memItems = await dbA.select(defTableMemItems,
                    where: getCreatedMemItem.where(),
                    whereArgs: getCreatedMemItem.whereArgs());
                expect(memItems.single[defColMemItemsValue.name],
                    enteringMemMemo2);
              },
            );
          },
        );

        group(
          ": Remove",
          () {
            Future<List<Map<String, Object?>>> selectFromMemsWhereName(
              String name,
            ) async {
              final where = Equals(defColMemsName.name, name);
              return await dbA.select(
                defTableMems,
                where: where.where(),
                whereArgs: where.whereArgs(),
              );
            }

            testWidgets(
              ": nothing on new.",
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(newMemFabFinder);
                await widgetTester.pumpAndSettle();

                expect(find.byKey(keyRemoveMem), findsNothing);
                expect(menuButtonIconFinder, findsNothing);
              },
            );

            testWidgets(
              ": cancel.",
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(menuButtonIconFinder);
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byKey(keyRemoveMem));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byKey(keyCancel));
                await widgetTester.pumpAndSettle();

                expect(
                  (await selectFromMemsWhereName(insertedMemName)).length,
                  1,
                );
              },
            );

            testWidgets(
              ": exec.",
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(menuButtonIconFinder);
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.byKey(keyRemoveMem));
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.byKey(keyOk));
                await widgetTester.pumpAndSettle();

                expect(
                  find.text(l10n.removeMemSuccessMessage(insertedMemName)),
                  findsOneWidget,
                );
                expect(
                  find.byKey(keyUndo),
                  findsOneWidget,
                );
                expect(find.text(insertedMemName), findsNothing);

                expect(
                    (await selectFromMemsWhereName(insertedMemName)).length, 0);
              },
            );

            testWidgets(
              ": exec on created.",
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(newMemFabFinder);
                await widgetTester.pumpAndSettle();

                const enteringMemName =
                    "$_scenarioName: Remove: exec on created - entering - mem - name";
                await widgetTester.enterText(
                    find.byKey(keyMemName), enteringMemName);
                await widgetTester.tap(find.byKey(keySaveMemFab));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(menuButtonIconFinder);
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.byKey(keyRemoveMem));
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.byKey(keyOk));
                await widgetTester.pumpAndSettle();

                expect(find.text(enteringMemName), findsNothing);
                expect(
                    (await selectFromMemsWhereName(enteringMemName)).length, 0);
              },
            );

            testWidgets(
              ": undo.",
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(menuButtonIconFinder);
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.byKey(keyRemoveMem));
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.byKey(keyOk));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byKey(keyUndo));
                await widgetTester.pumpAndSettle();

                expect(
                  find.text(l10n.undoMemSuccessMessage(insertedMemName)),
                  findsOneWidget,
                );

                expect(find.text(insertedMemName), findsOneWidget);
                expect(
                    (await selectFromMemsWhereName(insertedMemName)).length, 1);
                final where = Equals(defColMemItemsValue.name, insertedMemMemo);
                expect(
                  (await dbA.select(
                    defTableMemItems,
                    where: where.where(),
                    whereArgs: where.whereArgs(),
                  ))
                      .length,
                  1,
                );

                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                expect(find.text(insertedMemName), findsOneWidget);
                expect(find.text(insertedMemMemo), findsOneWidget);
              },
            );
          },
        );
      },
    );
