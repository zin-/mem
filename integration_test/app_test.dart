import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database_factory.dart';

import 'package:mem/main.dart' as app;
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/constants.dart';

// FIXME mem_detail_testと同じ定義。共通化したい
final memNameFinder = find.byType(TextFormField).at(0);
final saveFabFinder = find.byIcon(Icons.save_alt).at(0);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // FIXME なんか変じゃない？
    // TODO openしなくてもdeleteできるようにする
    await DatabaseManager().open(app.databaseDefinition);
    await DatabaseManager().delete(app.databaseDefinition.name);

    MemRepository.clear();
  });

  group(
    'Basic scenario',
    () {
      testWidgets(
        ': show new(empty) mem and create.',
        (widgetTester) async {
          const enteringMemName = 'entering mem name';

          await app.main();
          await widgetTester.pumpAndSettle();

          expect(
            (widgetTester.widget(memNameFinder) as TextFormField).initialValue,
            '',
          );

          await widgetTester.enterText(memNameFinder, enteringMemName);
          await widgetTester.tap(saveFabFinder);
          await widgetTester.pumpAndSettle();

          expect(find.text('Save success. $enteringMemName'), findsOneWidget);

          await Future.delayed(
            const Duration(seconds: defaultDismissDurationSeconds),
          );
          await widgetTester.pumpAndSettle();

          expect(find.text('Save success. $enteringMemName'), findsNothing);
        },
      );

      testWidgets(
        ': show saved mem and update.',
        (widgetTester) async {
          const savedMemName = 'saved mem name';
          final database = await DatabaseManager().open(app.databaseDefinition);
          final memTable = database.getTable(memTableName);
          final savedMemId = await memTable.insert({
            'name': savedMemName,
            'createdAt': DateTime.now(),
          });
          assert(savedMemId == 1);
          await DatabaseManager().close(app.databaseDefinition.name);

          const enteringMemName = 'entering mem name';

          await app.main();
          await widgetTester.pumpAndSettle();

          expect(
            (widgetTester.widget(memNameFinder) as TextFormField).initialValue,
            savedMemName,
          );

          await widgetTester.enterText(memNameFinder, enteringMemName);
          await widgetTester.tap(saveFabFinder);
          await widgetTester.pumpAndSettle();

          expect(find.text('Save success. $enteringMemName'), findsOneWidget);

          await Future.delayed(
            const Duration(seconds: defaultDismissDurationSeconds),
          );
          await widgetTester.pumpAndSettle();

          expect(find.text('Save success. $enteringMemName'), findsNothing);
        },
      );
    },
  );
}
