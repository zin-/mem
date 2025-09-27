import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/mems/detail/fab.dart';
import 'package:mem/features/mem_items/mem_items_view.dart';
import 'package:mem/features/mems/detail/app_bar/remove_mem_action.dart';
import 'package:mem/features/mems/transitions.dart';
// import 'package:mem/values/durations.dart';

import '../helpers.dart';

const _scenarioName = 'Memo detail scenario';

void main() => group(_scenarioName, () {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      late final DatabaseAccessor dbA;
      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });

      const baseMemName = "$_scenarioName - mem name";
      const baseMemMemo = "$_scenarioName - mem memo";

      const insertedMemName = "$baseMemName - inserted";
      const insertedMemMemo = "$baseMemMemo - inserted";
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

      // testWidgets("Show saved.", (widgetTester) async {
      //   await runApplication();
      //   await widgetTester.pumpAndSettle();
      //   await widgetTester.tap(find.text(insertedMemName));
      //   await widgetTester.pumpAndSettle();

      //   expect(
      //     widgetTester
      //         .widget<TextFormField>(find.byKey(keyMemName))
      //         .initialValue,
      //     insertedMemName,
      //   );
      //   expect(find.text(insertedMemName), findsOneWidget);
      //   expect(
      //     widgetTester
      //         .widget<TextFormField>(find.byKey(keyMemMemo))
      //         .initialValue,
      //     insertedMemMemo,
      //   );
      //   expect(find.text(insertedMemMemo), findsOneWidget);
      // });

      group("Save", () {
        const saveMemName = "$baseMemName: Save";
        const saveMemMemo = "$baseMemMemo: Save";

        // testWidgets('Create.', (widgetTester) async {
        //   widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
        //   widgetTester
        //       .ignoreMockMethodCallHandler(MethodChannelMock.permissionHandler);
        //   widgetTester.ignoreMockMethodCallHandler(
        //       MethodChannelMock.flutterLocalNotifications);

        //   await runApplication();
        //   await widgetTester.pumpAndSettle();
        //   await widgetTester.tap(newMemFabFinder);
        //   await widgetTester.pumpAndSettle();

        //   const enteringMemName = "$saveMemName: create - entering";
        //   const enteringMemMemo = "$saveMemMemo: create - entering";
        //   await widgetTester.enterText(find.byKey(keyMemName), enteringMemName);
        //   await widgetTester.enterText(find.byKey(keyMemMemo), enteringMemMemo);
        //   await widgetTester.tap(find.byKey(keySaveMemFab));
        //   await widgetTester.pump(const Duration(seconds: 5));

        //   expect(find.text(l10n.saveMemSuccessMessage(enteringMemName)),
        //       findsOneWidget);

        //   await widgetTester.pageBack();
        //   await widgetTester.pumpAndSettle(defaultTransitionDuration);

        //   expect(find.text(enteringMemName), findsOneWidget);
        //   expect(find.text(enteringMemMemo), findsNothing);

        //   final getCreatedMem = Equals(defColMemsName, enteringMemName);
        //   final mems = await dbA.select(defTableMems,
        //       where: getCreatedMem.where(),
        //       whereArgs: getCreatedMem.whereArgs());
        //   expect(mems.length, 1);
        //   final getCreatedMemItem = And([
        //     Equals(defFkMemItemsMemId, mems[0][defPkId.name]),
        //     Equals(defColMemItemsType, MemItemType.memo.name),
        //     Equals(defColMemItemsValue, enteringMemMemo)
        //   ]);
        //   final memItems = await dbA.select(defTableMemItems,
        //       where: getCreatedMemItem.where(),
        //       whereArgs: getCreatedMemItem.whereArgs());
        //   expect(memItems.length, 1);
        // });

        // testWidgets('Update.', (widgetTester) async {
        //   widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
        //   widgetTester
        //       .ignoreMockMethodCallHandler(MethodChannelMock.permissionHandler);
        //   widgetTester.ignoreMockMethodCallHandler(
        //       MethodChannelMock.flutterLocalNotifications);

        //   await runApplication();
        //   await widgetTester.pumpAndSettle();
        //   await widgetTester.tap(find.text(insertedMemName));
        //   await widgetTester.pumpAndSettle();

        //   await widgetTester.tap(memNameOnDetailPageFinder);
        //   await widgetTester.pump(waitShowSoftwareKeyboardDuration);
        //   const enteringMemNameText =
        //       "$_scenarioName: Save: Update - mem name - entering";
        //   await widgetTester.enterText(
        //       memNameOnDetailPageFinder, enteringMemNameText);
        //   // Androidエミュレーターでのテキスト入力反映を確実にするため、追加の待機時間を設ける
        //   await widgetTester.pump(const Duration(milliseconds: 500));
        //   await widgetTester.pumpAndSettle();

        //   // キーボードを閉じる（Androidエミュレーター対応）
        //   await widgetTester.testTextInput.receiveAction(TextInputAction.done);
        //   await widgetTester.pump(const Duration(milliseconds: 200));
        //   await widgetTester.pumpAndSettle();

        //   // テキストが表示されるまで最大10秒待機（Androidエミュレーター対応）
        //   bool textFound = false;
        //   for (int i = 0; i < 100; i++) {
        //     await widgetTester.pump(const Duration(milliseconds: 100));
        //     if (find.text(enteringMemNameText).evaluate().isNotEmpty) {
        //       textFound = true;
        //       break;
        //     }
        //     // デバッグ用：現在のテキストフィールドの内容を確認
        //     if (i % 20 == 0) {
        //       // ignore: avoid_print
        //       print(
        //           "Waiting for text '$enteringMemNameText' to appear... (attempt ${i + 1}/100)");
        //       // 現在のテキストフィールドの内容を確認
        //       final textFieldFinder = find.byType(TextField);
        //       if (textFieldFinder.evaluate().isNotEmpty) {
        //         final textField =
        //             widgetTester.widget<TextField>(textFieldFinder.first);
        //         // ignore: avoid_print
        //         print(
        //             "Current TextField value: '${textField.controller?.text}'");
        //       }
        //     }
        //   }

        //   if (!textFound) {
        //     // ignore: avoid_print
        //     print(
        //         "ERROR: Text '$enteringMemNameText' not found after 10 seconds");
        //     // ignore: avoid_print
        //     print("Available text widgets:");
        //     final allTextWidgets = find.byType(Text);
        //     for (int i = 0; i < allTextWidgets.evaluate().length; i++) {
        //       final textWidget =
        //           widgetTester.widget<Text>(allTextWidgets.at(i));
        //       // ignore: avoid_print
        //       print("  - '${textWidget.data}'");
        //     }
        //   }

        //   expect(find.text(enteringMemNameText), findsOneWidget);

        //   await widgetTester.tap(saveMemFabFinder);
        //   await widgetTester.pumpAndSettle();
        //   expect(find.text(l10n.saveMemSuccessMessage(enteringMemNameText)),
        //       findsOneWidget);

        //   await widgetTester.pageBack();
        //   await widgetTester.pumpAndSettle();
        //   expect(find.text(insertedMemName), findsNothing);
        //   expect(find.text(enteringMemNameText), findsOneWidget);

        //   await widgetTester.tap(find.text(enteringMemNameText));
        //   await widgetTester.pumpAndSettle();
        //   expect(find.text(insertedMemName), findsNothing);
        //   expect(find.text(enteringMemNameText), findsOneWidget);
        // });

        testWidgets('Twice on create.', retry: maxRetryCount,
            (widgetTester) async {
          widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
          widgetTester
              .ignoreMockMethodCallHandler(MethodChannelMock.permissionHandler);
          widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications);

          await runApplication();
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(newMemFabFinder);
          await widgetTester.pumpAndSettle();
          const enteringMemName = "$saveMemName: twice on create - entering";
          const enteringMemMemo = "$saveMemMemo: twice on create - entering";
          await widgetTester.enterText(find.byKey(keyMemName), enteringMemName);
          await widgetTester.enterText(find.byKey(keyMemMemo), enteringMemMemo);
          await widgetTester.tap(find.byKey(keySaveMemFab));
          await widgetTester.pumpAndSettle(waitSideEffectDuration);

          const enteringMemMemo2 = "$enteringMemMemo - 2";
          await widgetTester.enterText(
              find.byKey(keyMemMemo), enteringMemMemo2);
          await widgetTester.tap(find.byKey(keySaveMemFab));
          await widgetTester.pumpAndSettle(waitSideEffectDuration);

          final getCreatedMem = Equals(defColMemsName, enteringMemName);
          final mems = await dbA.select(defTableMems,
              where: getCreatedMem.where(),
              whereArgs: getCreatedMem.whereArgs());
          expect(mems.length, 1);
          final getCreatedMemItem = And([
            Equals(defFkMemItemsMemId, mems[0][defPkId.name]),
            Equals(defColMemItemsType, MemItemType.memo.name)
          ]);
          final memItems = await dbA.select(defTableMemItems,
              where: getCreatedMemItem.where(),
              whereArgs: getCreatedMemItem.whereArgs());
          expect(memItems.single[defColMemItemsValue.name], enteringMemMemo2);
        });

        // group('Archive', () {
        //   const insertedMemName = "$saveMemName: Archive: inserted";
        //   const unarchivedMemName = "$insertedMemName - unarchived";
        //   const archivedMemName = "$insertedMemName - archived";

        //   setUp(() async {
        //     final unarchivedMemId = await dbA.insert(defTableMems, {
        //       defColMemsName.name: unarchivedMemName,
        //       defColCreatedAt.name: DateTime.now(),
        //     });
        //     await dbA.insert(defTableMemItems, {
        //       defFkMemItemsMemId.name: unarchivedMemId,
        //       defColMemItemsType.name: MemItemType.memo.name,
        //       defColMemItemsValue.name: insertedMemMemo,
        //       defColCreatedAt.name: zeroDate,
        //     });
        //     final archivedMemId = await dbA.insert(defTableMems, {
        //       defColMemsName.name: archivedMemName,
        //       defColCreatedAt.name: DateTime.now(),
        //       defColArchivedAt.name: DateTime.now(),
        //     });
        //     await dbA.insert(defTableMemItems, {
        //       defFkMemItemsMemId.name: archivedMemId,
        //       defColMemItemsType.name: MemItemType.memo.name,
        //       defColMemItemsValue.name: insertedMemMemo,
        //       defColCreatedAt.name: zeroDate,
        //     });
        //   });

        //   testWidgets("Archive.", (widgetTester) async {
        //     await runApplication();
        //     await widgetTester.pumpAndSettle();
        //     await widgetTester.tap(find.text(unarchivedMemName));
        //     await widgetTester.pumpAndSettle();

        //     await widgetTester.tap(find.byIcon(Icons.more_vert));
        //     await widgetTester.pumpAndSettle();

        //     await widgetTester.tap(find.byIcon(Icons.archive));
        //     await widgetTester.pumpAndSettle();

        //     expect(find.text(unarchivedMemName), findsNothing);
        //     expect(find.text(l10n.archiveMemSuccessMessage(unarchivedMemName)),
        //         findsOneWidget);

        //     final findUnarchivedMem = Equals(defColMemsName, unarchivedMemName);
        //     final mems = await dbA.select(defTableMems,
        //         where: findUnarchivedMem.where(),
        //         whereArgs: findUnarchivedMem.whereArgs());
        //     expect(mems.length, 1);
        //     expect(mems.single[defColArchivedAt.name], isNotNull);
        //   });

        //   testWidgets("Unarchive.", (widgetTester) async {
        //     await runApplication();
        //     await widgetTester.pumpAndSettle();
        //     await widgetTester.tap(filterListIconFinder);
        //     await widgetTester.pumpAndSettle();
        //     await widgetTester.tap(showArchiveSwitchFinder);
        //     await widgetTester.pumpAndSettle();
        //     await closeMemListFilter(widgetTester);
        //     await widgetTester.pumpAndSettle();
        //     await widgetTester.tap(find.text(archivedMemName));
        //     await widgetTester.pumpAndSettle();

        //     await widgetTester.tap(find.byIcon(Icons.more_vert));
        //     await widgetTester.pumpAndSettle();

        //     await widgetTester.tap(find.byIcon(Icons.unarchive));
        //     await widgetTester.pumpAndSettle();

        //     expect(find.text(l10n.unarchiveMemSuccessMessage(archivedMemName)),
        //         findsOneWidget);

        //     final findArchivedMem = Equals(defColMemsName, archivedMemName);
        //     final mems = await dbA.select(defTableMems,
        //         where: findArchivedMem.where(),
        //         whereArgs: findArchivedMem.whereArgs());
        //     expect(mems.length, 1);
        //     expect(mems.single[defColArchivedAt.name], isNull);
        //   });
        // });
      });

      group('Remove', () {
        Future<List<Map<String, Object?>>> selectFromMemsWhereName(
          String name,
        ) async {
          final where = Equals(defColMemsName, name);
          return await dbA.select(
            defTableMems,
            where: where.where(),
            whereArgs: where.whereArgs(),
          );
        }

        testWidgets('Undo.', (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.text(insertedMemName));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(menuButtonIconFinder);
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byKey(keyRemoveMem));
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byKey(keyOk));
          await widgetTester.pumpAndSettle(waitSideEffectDuration);

          expect(
            find.text(l10n.removeMemSuccessMessage(insertedMemName)),
            findsOneWidget,
          );
          expect(find.text(insertedMemName), findsNothing);
          expect(
            (await selectFromMemsWhereName(insertedMemName)).length,
            0,
          );

          await widgetTester.tap(find.byKey(keyUndo));
          await widgetTester.pumpAndSettle();

          expect(
            find.text(l10n.undoMemSuccessMessage(insertedMemName)),
            findsOneWidget,
          );
          expect(find.text(insertedMemName), findsOneWidget);

          expect(
            (await selectFromMemsWhereName(insertedMemName)).length,
            1,
          );

          await widgetTester.tap(find.text(insertedMemName));
          await widgetTester.pumpAndSettle();

          expect(find.text(insertedMemName), findsOneWidget);
          expect(find.text(insertedMemMemo), findsOneWidget);
        });

        testWidgets("Nothing on new.", (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(newMemFabFinder);
          await widgetTester.pumpAndSettle();

          expect(find.byKey(keyRemoveMem), findsNothing);
          expect(menuButtonIconFinder, findsNothing);
        });

        testWidgets("Cancel.", (widgetTester) async {
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
        });

        testWidgets('On created.', (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(newMemFabFinder);
          await widgetTester.pumpAndSettle();
          const enteringMemName =
              "$baseMemName: Remove: exec on created - entering";
          await widgetTester.enterText(find.byKey(keyMemName), enteringMemName);
          await widgetTester.tap(find.byKey(keySaveMemFab));
          await widgetTester.pumpAndSettle(waitSideEffectDuration);

          await widgetTester.tap(menuButtonIconFinder);
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byKey(keyRemoveMem));
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.byKey(keyOk));
          await widgetTester.pumpAndSettle();

          expect(find.text(enteringMemName), findsNothing);
          expect((await selectFromMemsWhereName(enteringMemName)).length, 0);
        });
      });
    });
