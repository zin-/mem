import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/framework/database/accessor.dart';

import '../helpers.dart';

const _scenarioName = 'Mem relations scenario';

void main() => group(': $_scenarioName', () {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      late final DatabaseAccessor dbA;
      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });

      const baseMemName = "$_scenarioName - mem name";
      const sourceMemName = "$baseMemName - source";
      const targetMemName = "$baseMemName - target";

      late int sourceMemId;
      late int targetMemId;

      setUp(() async {
        await clearAllTestDatabaseRows(databaseDefinition);

        // ソースメムを作成
        sourceMemId = await dbA.insert(
          defTableMems,
          {
            defColMemsName.name: sourceMemName,
            defColCreatedAt.name: zeroDate,
          },
        );

        // ターゲットメムを作成
        targetMemId = await dbA.insert(
          defTableMems,
          {
            defColMemsName.name: targetMemName,
            defColCreatedAt.name: zeroDate,
          },
        );
      });

      testWidgets("Show relations list.", (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text(sourceMemName));
        await widgetTester.pumpAndSettle();

        // Relationsセクションが表示されることを確認
        expect(find.text("Relations"), findsOneWidget);
        expect(find.text("Add Relation"), findsOneWidget);
      });

      testWidgets("Add relation dialog opens.", (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text(sourceMemName));
        await widgetTester.pumpAndSettle();

        // Add Relationボタンをタップ
        await widgetTester.tap(find.text("Add Relation"));
        await widgetTester.pumpAndSettle();

        // ダイアログが開くことを確認
        expect(find.text("Add Relation"), findsNWidgets(2)); // タイトルとボタン
        expect(find.text("memを検索..."), findsOneWidget);
        expect(find.text("キャンセル"), findsOneWidget);
        expect(find.text("追加"), findsOneWidget);
      });

      testWidgets("Search mems in dialog.", (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text(sourceMemName));
        await widgetTester.pumpAndSettle();

        // Add Relationボタンをタップ
        await widgetTester.tap(find.text("Add Relation"));
        await widgetTester.pumpAndSettle();

        // 検索フィールドにテキストを入力
        await widgetTester.enterText(find.text("memを検索..."), "target");
        await widgetTester.pumpAndSettle();

        // ターゲットメムが表示されることを確認
        expect(find.text(targetMemName), findsOneWidget);
      });

      testWidgets("Select and add relation.", (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text(sourceMemName));
        await widgetTester.pumpAndSettle();

        // Add Relationボタンをタップ
        await widgetTester.tap(find.text("Add Relation"));
        await widgetTester.pumpAndSettle();

        // ターゲットメムを選択
        await widgetTester.tap(find.text(targetMemName));
        await widgetTester.pumpAndSettle();

        // 追加ボタンをタップ
        await widgetTester.tap(find.text("追加"));
        await widgetTester.pumpAndSettle();

        // ダイアログが閉じることを確認
        expect(find.text("Add Relation"), findsOneWidget); // ボタンのみ残る
        expect(find.text("memを検索..."), findsNothing);
      });

      testWidgets("Cancel dialog.", (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text(sourceMemName));
        await widgetTester.pumpAndSettle();

        // Add Relationボタンをタップ
        await widgetTester.tap(find.text("Add Relation"));
        await widgetTester.pumpAndSettle();

        // キャンセルボタンをタップ
        await widgetTester.tap(find.text("キャンセル"));
        await widgetTester.pumpAndSettle();

        // ダイアログが閉じることを確認
        expect(find.text("Add Relation"), findsOneWidget); // ボタンのみ残る
        expect(find.text("memを検索..."), findsNothing);
      });

      testWidgets("Show existing relations.", (widgetTester) async {
        // 既存のリレーションを作成
        await dbA.insert(
          defTableMemRelations,
          {
            defFkMemRelationsSourceMemId.name: sourceMemId,
            defFkMemRelationsTargetMemId.name: targetMemId,
            defColMemRelationsType.name: "related",
            defColCreatedAt.name: zeroDate,
          },
        );

        await runApplication();
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text(sourceMemName));
        await widgetTester.pumpAndSettle();

        // 既存のリレーションが表示されることを確認
        expect(find.text(targetMemName), findsOneWidget);
      });
    });
