import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/logger.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/repository.dart';

void main() {
  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'MemItem is archived',
    (widgetTester) async {
      await DatabaseManager().open(app.databaseDefinition);
      await DatabaseManager().delete(app.databaseDefinition.name);

      const savedMemName = 'saved mem name';
      final database = await DatabaseManager().open(app.databaseDefinition);
      final memTable = database.getTable(memTableDefinition.name);
      final savedMemId = await memTable.insert({
        memNameColumnName: savedMemName,
        createdAtColumnName: DateTime.now(),
        archivedAtColumnName: null,
      });
      assert(savedMemId == 1);
      final memItemTable = database.getTable(memItemTableDefinition.name);
      const archivedMemMemo = 'archived mem memo';
      await memItemTable.insert({
        memIdColumnName: savedMemId,
        memItemTypeColumnName: MemItemType.memo.name,
        memItemValueColumnName: archivedMemMemo,
        createdAtColumnName: DateTime.now(),
        archivedAtColumnName: DateTime.now(),
      });

      await app.main();
      await widgetTester.pumpAndSettle();

      await widgetTester.tap(find.text(savedMemName));
      await widgetTester.pumpAndSettle();

      expect(find.text(savedMemName), findsOneWidget);
      expect(find.text(archivedMemMemo), findsOneWidget);
    },
  );
}
