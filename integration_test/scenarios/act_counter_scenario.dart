import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/logger/i/type.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';

import '../_helpers.dart';

void main() {
  LogService(Level.verbose);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await clearDatabase();
  });

  testActCounterConfigure();
}

void testActCounterConfigure() => group(
      'ActCounter test',
      () {
        const savedMemName = 'ActCounter test: saved mem name';
        late int savedMemId;

        setUp(() async {
          final memTable =
              (await DatabaseManager(onTest: true).open(databaseDefinition))
                  .getTable(memTableDefinition.name);

          savedMemId = await memTable.insert({
            defMemName.name: savedMemName,
            createdAtColumnName: DateTime.now(),
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
