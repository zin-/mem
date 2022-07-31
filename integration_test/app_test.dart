import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/logger.dart';

import 'package:mem/main.dart' as app;
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/views/constants.dart';

import '../test/widget/mem_detail_test.dart';
import '../test/widget/mem_list_page_test.dart';

void main() {
  Logger(level: Level.verbose);
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // FIXME openしないとdeleteできないのは、実際のDatabaseと挙動が異なる
    // 今の実装だと難しいっぽい。いつかチャレンジする
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
          const enteringMemNameSecond = 'second';

          await app.main();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(showNewMemFabFinder);
          await widgetTester.pumpAndSettle();

          expect(
            (widgetTester.widget(memNameTextFormFieldFinder) as TextFormField)
                .initialValue,
            '',
          );

          await widgetTester.enterText(
              memNameTextFormFieldFinder, enteringMemName);
          await widgetTester.tap(saveFabFinder);
          await widgetTester.pumpAndSettle();

          expect(find.text('Save success. $enteringMemName'), findsOneWidget);

          await Future.delayed(
            const Duration(seconds: defaultDismissDurationSeconds),
          );
          await widgetTester.pumpAndSettle();

          expect(find.text('Save success. $enteringMemName'), findsNothing);

          await widgetTester.enterText(
            memNameTextFormFieldFinder,
            enteringMemNameSecond,
          );
          await widgetTester.tap(saveFabFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();

          expect(find.text(enteringMemName), findsNothing);
          expect(
            getMemNameTextOnListAt(widgetTester, 0).data,
            enteringMemNameSecond,
          );
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
          const enteringMemNameSecond = 'second';

          await app.main();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(memListTileFinder.at(0));
          await widgetTester.pumpAndSettle();

          expect(
            (widgetTester.widget(memNameTextFormFieldFinder) as TextFormField)
                .initialValue,
            savedMemName,
          );

          await widgetTester.enterText(
              memNameTextFormFieldFinder, enteringMemName);
          await widgetTester.tap(saveFabFinder);
          await widgetTester.pumpAndSettle();

          expect(find.text('Save success. $enteringMemName'), findsOneWidget);

          await Future.delayed(
            const Duration(seconds: defaultDismissDurationSeconds),
          );
          await widgetTester.pumpAndSettle();

          expect(find.text('Save success. $enteringMemName'), findsNothing);

          await widgetTester.enterText(
            memNameTextFormFieldFinder,
            enteringMemNameSecond,
          );
          await widgetTester.tap(saveFabFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();

          expect(find.text(enteringMemName), findsNothing);
          expect(
            getMemNameTextOnListAt(widgetTester, 0).data,
            enteringMemNameSecond,
          );
        },
      );
    },
  );
}
