import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
// import 'package:mem/databases/table_definitions/mem_relations.dart';
// import 'package:mem/features/mem_relations/mem_relation.dart';
// import 'package:mem/features/mem_relations/mem_relation_search_dialog.dart';
// import 'package:mem/features/mems/detail/fab.dart';
import 'package:mem/framework/database/accessor.dart';

import '../helpers.dart';

const _scenarioName = 'Mem relations scenario';

void main() => group(': $_scenarioName', () {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      late final DriftDatabaseAccessor dbA;
      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });

      const baseMemName = "$_scenarioName - mem name";
      const sourceMemName = "$baseMemName - source";
      const targetMemName = "$baseMemName - target";
      const otherMemName = "$baseMemName - other";

      // late int sourceMemId;
      // late int targetMemId;

      setUp(() async {
        await clearAllTestDatabaseRows(databaseDefinition);

        // sourceMemId =
        await dbA.insert(
          defTableMems,
          {
            defColMemsName.name: sourceMemName,
            defColCreatedAt.name: zeroDate,
          },
        );
        // targetMemId =
        await dbA.insert(
          defTableMems,
          {
            defColMemsName.name: targetMemName,
            defColCreatedAt.name: zeroDate,
          },
        );
        await dbA.insert(
          defTableMems,
          {
            defColMemsName.name: otherMemName,
            defColCreatedAt.name: zeroDate,
          },
        );
      });

      // testWidgets("Show relations list.", (widgetTester) async {
      //   await runApplication();
      //   await widgetTester.pumpAndSettle();
      //   await widgetTester.tap(find.text(sourceMemName));
      //   await widgetTester.pumpAndSettle();

      //   expect(find.text("Relations"), findsOneWidget);
      //   expect(find.text("Add Relation"), findsOneWidget);
      // });

      // group("Saved", () {
      //   setUp(() async {
      //     await dbA.insert(
      //       defTableMemRelations,
      //       {
      //         defFkMemRelationsSourceMemId.name: sourceMemId,
      //         defFkMemRelationsTargetMemId.name: targetMemId,
      //         defColMemRelationsType.name: MemRelationType.prePost.name,
      //         defColCreatedAt.name: zeroDate,
      //       },
      //     );
      //   });

      //   testWidgets("Show existing relations.", (widgetTester) async {
      //     await runApplication();
      //     await widgetTester.pumpAndSettle();
      //     await widgetTester.tap(find.text(sourceMemName));
      //     await widgetTester.pumpAndSettle();

      //     expect(find.text(targetMemName), findsOneWidget);
      //   });
      // });

      // group("SearchMemRelationDialog", () {
      //   testWidgets("Add relation dialog opens.", (widgetTester) async {
      //     await runApplication();
      //     await widgetTester.pumpAndSettle();
      //     await widgetTester.tap(find.text(sourceMemName));
      //     await widgetTester.pumpAndSettle();

      //     await widgetTester.tap(find.text("Add Relation"));
      //     await widgetTester.pumpAndSettle();

      //     expect(find.text("Add Relation"), findsNWidgets(2));
      //     expect(find.text("memを検索..."), findsOneWidget);
      //     expect(find.text("キャンセル"), findsOneWidget);
      //     expect(find.text("追加"), findsOneWidget);
      //   });

      //   testWidgets("Search mems in dialog.", (widgetTester) async {
      //     await runApplication();
      //     await widgetTester.pumpAndSettle();
      //     await widgetTester.tap(find.text(sourceMemName));
      //     await widgetTester.pumpAndSettle();

      //     await widgetTester.tap(find.text("Add Relation"));
      //     await widgetTester.pumpAndSettle();

      //     await widgetTester.enterText(
      //       find.byKey(searchMemRelationDialogSearchFieldKey),
      //       "target",
      //     );
      //     await widgetTester.pumpAndSettle();

      //     expect(find.text(targetMemName), findsOneWidget);
      //     expect(find.text(otherMemName), findsNothing);
      //   });

      //   testWidgets("Select and add relation.", (widgetTester) async {
      //     await runApplication();
      //     await widgetTester.pumpAndSettle();
      //     await widgetTester.tap(find.text(sourceMemName));
      //     await widgetTester.pumpAndSettle();

      //     // Add Relationボタンをタップ
      //     await widgetTester.tap(find.text("Add Relation"));
      //     await widgetTester.pumpAndSettle();

      //     // ターゲットメムを選択
      //     await widgetTester.tap(find.text(targetMemName));
      //     await widgetTester.pumpAndSettle();

      //     // 追加ボタンをタップ
      //     await widgetTester.tap(find.text("追加"));
      //     await widgetTester.pumpAndSettle();

      //     // ダイアログが閉じることを確認
      //     expect(find.text("Add Relation"), findsOneWidget); // ボタンのみ残る
      //     expect(find.text("memを検索..."), findsNothing);
      //   });

      //   testWidgets("Cancel dialog.", (widgetTester) async {
      //     await runApplication();
      //     await widgetTester.pumpAndSettle();
      //     await widgetTester.tap(find.text(sourceMemName));
      //     await widgetTester.pumpAndSettle();

      //     // Add Relationボタンをタップ
      //     await widgetTester.tap(find.text("Add Relation"));
      //     await widgetTester.pumpAndSettle();

      //     // キャンセルボタンをタップ
      //     await widgetTester.tap(find.text("キャンセル"));
      //     await widgetTester.pumpAndSettle();

      //     // ダイアログが閉じることを確認
      //     expect(find.text("Add Relation"), findsOneWidget); // ボタンのみ残る
      //     expect(find.text("memを検索..."), findsNothing);
      //   });
      // });

      // testWidgets("[flaky]Save relation.", (widgetTester) async {
      //   await runApplication();
      //   await widgetTester.pumpAndSettle();
      //   await widgetTester.tap(find.text(sourceMemName));
      //   await widgetTester.pumpAndSettle();

      //   await widgetTester.tap(find.text("Add Relation"));
      //   await widgetTester.pumpAndSettle();

      //   await widgetTester.tap(find.text(targetMemName));
      //   await widgetTester.pumpAndSettle();

      //   await widgetTester.tap(find.text("追加"));
      //   await widgetTester.pumpAndSettle();

      //   expect(find.text("Add Relation"), findsOneWidget);
      //   expect(find.text("memを検索..."), findsNothing);

      //   await widgetTester.tap(find.byKey(keySaveMemFab));
      //   await widgetTester.pumpAndSettle();

      //   expect(find.text(l10n.saveMemSuccessMessage(sourceMemName)),
      //       findsOneWidget);

      //   final savedRelations = await dbA.select(
      //     defTableMemRelations,
      //     where: "${defFkMemRelationsSourceMemId.name} = ?",
      //     whereArgs: [sourceMemId],
      //   );
      //   expect(savedRelations.length, 1);
      //   expect(savedRelations.first[defFkMemRelationsTargetMemId.name],
      //       targetMemId);
      //   expect(savedRelations.first[defColMemRelationsType.name],
      //       MemRelationType.prePost.name);
      // });
    });
