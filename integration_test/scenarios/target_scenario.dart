import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/features/targets/target_view.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/time_text_form_field.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/mems/detail/fab.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/framework/view/integer_text_form_field.dart';

import 'helpers.dart';

const _scenarioName = "Target scenario";

void main() => group(_scenarioName, () {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      late final DatabaseAccessor dbA;
      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });

      const insertedMemName = '$_scenarioName: inserted - mem name';
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
          defTableTargets,
          {
            defFkTargetMemId.name: insertedMemId,
            defColTargetType.name: TargetType.moreThan.name,
            defColTargetUnit.name: TargetUnit.count.name,
            defColTargetValue.name: 1,
            defColTargetPeriod.name: Period.all.name,
            defColCreatedAt.name: zeroDate,
          },
        );
      });

      testWidgets("Show target.", (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(find.text(insertedMemName));
        await widgetTester.pumpAndSettle();

        expect(find.text(TargetType.moreThan.name), findsOneWidget);
        expect(find.text(TargetUnit.count.name), findsOneWidget);
        expect(
            widgetTester
                .widget<IntegerTextFormField>(
                  find.byKey(keyTargetValue),
                )
                .initialValue,
            1);
        expect(find.text(Period.all.name), findsOneWidget);

        await widgetTester.tap(find.byKey(keySaveMemFab));
        await widgetTester.pumpAndSettle();

        final getCreatedTarget = And([
          Equals(defFkTargetMemId, insertedMemId),
        ]);
        final targets = await dbA.select(defTableTargets,
            where: getCreatedTarget.where(),
            whereArgs: getCreatedTarget.whereArgs());
        expect(targets.length, 1);
        expect(targets[0][defColCreatedAt.name],
            isNot(targets[0][defColUpdatedAt.name]));
      });

      testWidgets("[flaky]Create target.", (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(find.byIcon(Icons.add));
        await widgetTester.pumpAndSettle(waitShowSoftwareKeyboardDuration);

        // ウィジェットが表示されるまで待機
        await widgetTester.pump(const Duration(seconds: 1));

        // ソフトキーボードを閉じる
        await widgetTester.testTextInput.receiveAction(TextInputAction.done);
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(find.text(TargetType.equalTo.name));
        await widgetTester.pumpAndSettle(waitShowSoftwareKeyboardDuration);
        await widgetTester.tap(find.text(TargetType.lessThan.name));
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(find.text(TargetUnit.count.name));
        await widgetTester.pumpAndSettle(waitShowSoftwareKeyboardDuration);
        await widgetTester.tap(find.text(TargetUnit.time.name));
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(
          find.descendant(
              of: find.byKey(keyTimeTextFormField),
              matching: find.byIcon(Icons.add)),
        );
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text("h").at(1));
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text("OK"));
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(find.text(Period.aDay.name));
        await widgetTester.pumpAndSettle(waitShowSoftwareKeyboardDuration);
        await widgetTester.tap(find.text(Period.aWeek.name));
        await widgetTester.pumpAndSettle();

        const enteringMemName = "$_scenarioName - entering - mem name";
        await widgetTester.enterText(find.byKey(keyMemName), enteringMemName);
        await widgetTester.pump();
        await widgetTester.tap(find.byKey(keySaveMemFab));
        await widgetTester.pumpAndSettle();

        final getCreatedMem = Equals(defColMemsName, enteringMemName);
        final mems = await dbA.select(defTableMems,
            where: getCreatedMem.where(), whereArgs: getCreatedMem.whereArgs());
        expect(mems.length, 1);
        final getCreatedTarget = And([
          Equals(defFkTargetMemId, mems[0][defPkId.name]),
        ]);
        final targets = await dbA.select(defTableTargets,
            where: getCreatedTarget.where(),
            whereArgs: getCreatedTarget.whereArgs());
        expect(targets.length, 1);
        expect(targets[0][defColTargetType.name], TargetType.lessThan.name);
        expect(targets[0][defColTargetUnit.name], TargetUnit.time.name);
        expect(targets[0][defColTargetValue.name], 3600);
        expect(targets[0][defColTargetPeriod.name], Period.aWeek.name);
      });

      testWidgets("Clear target.", (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.text(insertedMemName));
        await widgetTester.pumpAndSettle();

        await widgetTester.enterText(find.byKey(keyTargetValue), "0");
        await widgetTester.pumpAndSettle();
        await widgetTester.pump();
        await widgetTester.tap(find.byKey(keySaveMemFab));
        await widgetTester.pumpAndSettle(waitSideEffectDuration);

        final getCreatedMem = Equals(defColMemsName, insertedMemName);
        final mems = await dbA.select(defTableMems,
            where: getCreatedMem.where(), whereArgs: getCreatedMem.whereArgs());
        expect(mems.length, 1);
        final getCreatedTarget = And([
          Equals(defFkTargetMemId, mems[0][defPkId.name]),
        ]);
        final targets = await dbA.select(defTableTargets,
            where: getCreatedTarget.where(),
            whereArgs: getCreatedTarget.whereArgs());
        expect(targets, isEmpty);
      });
    });
