import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database_factory.dart';

import 'package:mem/main.dart' as app;
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/constants.dart';

import '../test/widget/mem_detail_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // FIXME なんか変じゃない？
    // TODO openしなくてもdeleteできるようにする
    await DatabaseManager().open(app.databaseDefinition);
    await DatabaseManager().delete(app.databaseDefinition.name);
  });

  group(
    'Basic scenario',
    () {
      testWidgets(
        ': show new(empty) mem and create.',
        (widgetTester) async {
          const enteringMemName = 'entering mem name';

          app.main();
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
          await memTable.insert({
            'name': savedMemName,
            'createdAt': DateTime.now(),
          });

          const enteringMemName = 'entering mem name';

          app.main();
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
