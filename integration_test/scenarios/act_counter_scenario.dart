import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/database/definition.dart';
import 'package:mem/main.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testActCounterConfigure();
}

void testActCounterConfigure() => group(
      'ActCounter test',
      () {
        const savedMemName = 'ActCounter test: saved mem name';
        late int savedMemId;

        setUp(() async {
          final db =
              await DatabaseManager(onTest: true).open(databaseDefinition);

          await resetDatabase(db);

          savedMemId = await db.getTable(memTableDefinition.name).insert({
            defMemName.name: savedMemName,
            createdAtColDef.name: DateTime.now(),
          });
        });

        testWidgets(
          ': select saved mem.',
          (widgetTester) async {
            await launchActCounterConfigure();
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(Text).at(0)) as Text).data,
              'Select target',
            );
            expect(
              (widgetTester.widget(find.byType(Radio<MemId>)) as Radio)
                  .groupValue,
              null,
            );
            await widgetTester.tap(find.text(savedMemName));
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(Radio<MemId>)) as Radio)
                  .groupValue,
              savedMemId,
            );
            await widgetTester.tap(find.byIcon(Icons.check));
            // FIXME MethodChannelの実行までを確認するべき
            //  integration testからtestに移動する
          },
        );
      },
    );
