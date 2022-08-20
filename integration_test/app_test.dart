import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/logger.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/main.dart' as app;

import '../test/widget/mem_detail_menu_test.dart';
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

  group('Basic scenario', () {
    testWidgets(': create.', (widgetTester) async {
      const enteringMemName = 'entering mem name';

      await app.main();
      await widgetTester.pumpAndSettle();

      await widgetTester.tap(showNewMemFabFinder);
      await widgetTester.pumpAndSettle();

      await enterMemNameAndSave(widgetTester, enteringMemName);

      await widgetTester.pageBack();
      await widgetTester.pumpAndSettle();

      expectMemNameTextOnListAt(widgetTester, 0, enteringMemName);
    });

    testWidgets(': update.', (widgetTester) async {
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

      expectMemNameTextOnListAt(widgetTester, 0, savedMemName);

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle();

      await enterMemNameAndSave(widgetTester, enteringMemName);

      expect(saveMemSuccessFinder(enteringMemName), findsOneWidget);

      await widgetTester.pageBack();
      await widgetTester.pumpAndSettle();

      expectMemNameTextOnListAt(widgetTester, 0, enteringMemName);
      expect(find.text(savedMemName), findsNothing);
    });

    testWidgets(': archive.', (widgetTester) async {
      const enteringMemName = 'entering mem name';

      await app.main();
      await widgetTester.pumpAndSettle();

      await widgetTester.tap(showNewMemFabFinder);
      await widgetTester.pumpAndSettle();

      await enterMemNameAndSave(widgetTester, enteringMemName);

      await widgetTester.tap(archiveButtonFinder);
      await widgetTester.pumpAndSettle();

      expect(find.text(enteringMemName), findsNothing);

      await widgetTester.tap(memListFilterButton);
      await widgetTester.pumpAndSettle();

      await widgetTester.tap(findShowArchiveSwitch);
      await widgetTester.pumpAndSettle();

      await closeMemListFilter(widgetTester);

      expectMemNameTextOnListAt(widgetTester, 0, enteringMemName);
    });

    testWidgets(': remove.', (widgetTester) async {
      const savedMemName = 'saved mem name';
      final database = await DatabaseManager().open(app.databaseDefinition);
      final memTable = database.getTable(memTableName);
      final savedMemId = await memTable.insert({
        'name': savedMemName,
        'createdAt': DateTime.now(),
      });
      assert(savedMemId == 1);
      await DatabaseManager().close(app.databaseDefinition.name);

      await app.main();
      await widgetTester.pumpAndSettle();

      await widgetTester.tap(memListTileFinder.at(0));
      await widgetTester.pumpAndSettle();

      await showRemoveMemConfirmDialog(widgetTester);

      await widgetTester.tap(okButtonFinder);
      await widgetTester.pumpAndSettle();

      expect(find.text(savedMemName), findsNothing);

      await widgetTester.tap(memListFilterButton);
      await widgetTester.pumpAndSettle();

      await widgetTester.tap(findShowArchiveSwitch);
      await widgetTester.pumpAndSettle();

      await closeMemListFilter(widgetTester);

      expect(find.text(savedMemName), findsNothing);
    });
  });
}
