import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/logger.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/main.dart' as app;

import '../test/widget/mem_detail_page_test.dart';
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
      // FIXME 1つのテストで色々やろうとし過ぎかも
      testWidgets(
        ': show new(empty) mem and create.',
        (widgetTester) async {
          const enteringMemName = 'entering mem name';
          const enteringMemNameSecond = 'entering mem name second';

          await app.main();
          await widgetTester.pump();

          await widgetTester.tap(showNewMemFabFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(showNewMemFabFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(archiveButtonFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(showNewMemFabFinder);
          await widgetTester.pumpAndSettle();

          await enterMemNameAndSave(widgetTester, enteringMemName);

          await checkSavedSnackBarAndDismiss(widgetTester, enteringMemName);

          await enterMemNameAndSave(widgetTester, enteringMemNameSecond);
          await checkSavedSnackBarAndDismiss(
            widgetTester,
            enteringMemNameSecond,
          );

          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();

          expect(find.text(enteringMemName), findsNothing);
          expectMemNameTextOnListAt(widgetTester, 0, enteringMemNameSecond);

          await widgetTester.tap(showNewMemFabFinder);
          await widgetTester.pumpAndSettle();

          expect(find.text(enteringMemNameSecond), findsNothing);
        },
      );

      testWidgets(
        ': show saved mem and update and archive.',
        (widgetTester) async {
          const savedMemName = 'saved mem name';
          const updatingMemName = 'updating mem name';
          final database = await DatabaseManager().open(app.databaseDefinition);
          final memTable = database.getTable(memTableName);
          final savedMemId = await memTable.insert({
            'name': savedMemName,
            'createdAt': DateTime.now(),
          });
          assert(savedMemId == 1);
          final updatingMemId = await memTable.insert({
            'name': updatingMemName,
            'createdAt': DateTime.now(),
          });
          assert(updatingMemId == 2);
          await DatabaseManager().close(app.databaseDefinition.name);

          const enteringMemName = 'entering mem name';
          const enteringMemNameSecond = 'entering mem name second';

          await app.main();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(memListTileFinder.at(1));
          await widgetTester.pumpAndSettle();

          await enterMemNameAndSave(widgetTester, enteringMemName);

          await checkSavedSnackBarAndDismiss(widgetTester, enteringMemName);

          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();

          expect(find.text(updatingMemName), findsNothing);
          expect(
            getMemNameTextOnListAt(widgetTester, 0).data,
            savedMemName,
          );
          expect(
            getMemNameTextOnListAt(widgetTester, 1).data,
            enteringMemName,
          );

          await widgetTester.tap(memListTileFinder.at(0));
          await widgetTester.pumpAndSettle();

          await widgetTester.enterText(
            memNameTextFormFieldFinder,
            enteringMemNameSecond,
          );
          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();

          expect(find.text(updatingMemName), findsNothing);
          expect(find.text(enteringMemNameSecond), findsNothing);
          expect(
            getMemNameTextOnListAt(widgetTester, 0).data,
            savedMemName,
          );
          expect(
            getMemNameTextOnListAt(widgetTester, 1).data,
            enteringMemName,
          );

          await widgetTester.tap(memListTileFinder.at(0));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(archiveButtonFinder);
          await widgetTester.pumpAndSettle();

          expect(find.text(updatingMemName), findsNothing);
          expect(find.text(enteringMemNameSecond), findsNothing);
          expect(find.text(savedMemName), findsNothing);
          expect(
            getMemNameTextOnListAt(widgetTester, 0).data,
            enteringMemName,
          );
        },
      );
    },
  );
}
