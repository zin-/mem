import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/logger.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/repositories/repository.dart';

const defaultDuration = Duration(seconds: 1);

void main() {
  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // FIXME openしないとdeleteできないのは、実際のDatabaseと挙動が異なる
    // 今の実装だと難しいっぽい。いつかチャレンジする
    await DatabaseManager().open(app.databaseDefinition);
    await DatabaseManager().delete(app.databaseDefinition.name);
  });

  group('Memo scenario', () {
    testWidgets(
      ': create',
      (widgetTester) async {
        await app.main(languageCode: 'en');
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(find.byIcon(Icons.add));
        await widgetTester.pumpAndSettle(defaultDuration);

        const enteringMemName = 'entering mem name';
        const enteringMemMemo = 'entering mem memo';

        await widgetTester.enterText(
            memNameTextFormFieldFinder, enteringMemName);
        await widgetTester.enterText(
            memMemoTextFormFieldFinder, enteringMemMemo);

        await widgetTester.tap(saveFabFinder);
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.pageBack();
        await widgetTester.pumpAndSettle(defaultDuration);

        expect(find.text(enteringMemName), findsOneWidget);
        expect(find.text(enteringMemMemo), findsNothing);
      },
      tags: 'Medium',
    );

    testWidgets(
      ': update',
      (widgetTester) async {
        const savedMemName = 'saved mem name';
        const savedMemMemo = 'saved mem memo';
        await prepareSavedData(savedMemName, savedMemMemo);

        await app.main(languageCode: 'en');
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(find.text(savedMemName));
        await widgetTester.pumpAndSettle(defaultDuration);

        const enteringMemName = 'entering mem name';
        const enteringMemMemo = 'entering mem memo';

        await widgetTester.enterText(
            memNameTextFormFieldFinder, enteringMemName);
        await widgetTester.enterText(
            memMemoTextFormFieldFinder, enteringMemMemo);

        await widgetTester.tap(saveFabFinder);
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.pageBack();
        // FIXME 2秒は長すぎる。何が原因で見つからないのか分からないので一旦時間を伸ばしてみた
        await widgetTester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text(enteringMemName), findsOneWidget);
        expect(find.text(enteringMemMemo), findsNothing);
        expect(find.text(savedMemName), findsNothing);
      },
      tags: 'Medium',
    );

    testWidgets(
      ': archive',
      (widgetTester) async {
        const savedMemName = 'saved mem name';
        const savedMemMemo = 'saved mem memo';
        await prepareSavedData(savedMemName, savedMemMemo);

        await app.main(languageCode: 'en');
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(find.text(savedMemName));
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(find.byIcon(Icons.archive));
        await widgetTester.pumpAndSettle(defaultDuration);

        expect(
          find.descendant(
            of: find.byType(Text),
            matching: find.text(savedMemName),
          ),
          findsNothing,
        );

        await widgetTester.tap(memListFilterButton);
        await widgetTester.pumpAndSettle(defaultDuration);
        await widgetTester.tap(findShowArchiveSwitch);
        await widgetTester.pumpAndSettle(defaultDuration);

        expect(find.text(savedMemName), findsOneWidget);
      },
      tags: 'Medium',
    );

    testWidgets(
      ': unarchive',
      (widgetTester) async {
        const savedMemName = 'archived mem name';
        const savedMemMemo = 'archived mem memo';
        await prepareSavedData(savedMemName, savedMemMemo, isArchived: true);

        await app.main(languageCode: 'en');
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(memListFilterButton);
        await widgetTester.pumpAndSettle(defaultDuration);
        await widgetTester.tap(findShowArchiveSwitch);
        await widgetTester.tap(findShowNotArchiveSwitch);
        await closeMemListFilter(widgetTester);
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(find.text(savedMemName));
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(find.byIcon(Icons.unarchive));
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.pageBack();
        await widgetTester.pumpAndSettle(defaultDuration);

        expect(find.text(savedMemName), findsNothing);

        await widgetTester.tap(memListFilterButton);
        await widgetTester.pumpAndSettle(defaultDuration);
        await widgetTester.tap(findShowNotArchiveSwitch);
        await closeMemListFilter(widgetTester);
        await widgetTester.pumpAndSettle(defaultDuration);

        expect(find.text(savedMemName), findsOneWidget);
      },
      tags: 'Medium',
    );

    testWidgets(
      ': remove',
      (widgetTester) async {
        const savedMemName = 'saved mem name';
        const savedMemMemo = 'saved mem memo';
        await prepareSavedData(savedMemName, savedMemMemo);

        await app.main(languageCode: 'en');
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(find.text(savedMemName));
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.more_vert),
          ),
        );
        await widgetTester.pumpAndSettle(defaultDuration);
        await widgetTester.tap(find.byIcon(Icons.delete));
        await widgetTester.pumpAndSettle(defaultDuration);
        await widgetTester.tap(find.text('OK'));
        await widgetTester.pumpAndSettle(defaultDuration);

        expect(find.text(savedMemName), findsNothing);

        await widgetTester.tap(memListFilterButton);
        await widgetTester.pumpAndSettle(defaultDuration);
        await widgetTester.tap(findShowArchiveSwitch);
        await widgetTester.pumpAndSettle(defaultDuration);
        await closeMemListFilter(widgetTester);

        expect(find.text(savedMemName), findsNothing);
      },
      tags: 'Medium',
    );
  });

  group('Todo scenario', () {
    testWidgets(
      ': done',
      (widgetTester) async {
        const savedMemName = 'saved mem name';
        const savedMemMemo = 'saved mem memo';
        await prepareSavedData(savedMemName, savedMemMemo);

        await app.main(languageCode: 'en');
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(find.byType(Checkbox));
        await widgetTester.pumpAndSettle(defaultDuration);

        expect(find.text(savedMemName), findsNothing);

        await widgetTester.tap(memListFilterButton);
        await widgetTester.pumpAndSettle(defaultDuration);
        await widgetTester.tap(find.byType(Switch).at(3));
        await closeMemListFilter(widgetTester);

        expect(find.text(savedMemName), findsOneWidget);
      },
      tags: 'Medium',
    );
  });

  group('Edge scenario', () {
    testWidgets(
      'MemItem is nothing',
      (widgetTester) async {
        const savedMemName = 'saved mem name';
        final database = await DatabaseManager().open(app.databaseDefinition);
        final memTable = database.getTable(memTableDefinition.name);
        await memTable.insert({
          memNameColumnName: savedMemName,
          createdAtColumnName: DateTime.now(),
          archivedAtColumnName: null,
        });

        await app.main(languageCode: 'en');
        await widgetTester.pumpAndSettle(defaultDuration);

        await widgetTester.tap(find.text(savedMemName));
        await widgetTester.pumpAndSettle(defaultDuration);

        expect(find.text(savedMemName), findsOneWidget);
        expect(widgetTester.widgetList(find.byType(TextFormField)).length, 3);
      },
      tags: 'Medium',
    );
  });
}

final memListFilterButton = find.byIcon(Icons.filter_list);
final findShowNotArchiveSwitch = find.byType(Switch).at(0);
final findShowArchiveSwitch = find.byType(Switch).at(1);

Future closeMemListFilter(WidgetTester widgetTester) async {
  await widgetTester.tapAt(const Offset(0, 0));
  await widgetTester.pumpAndSettle(defaultDuration);
}

final memNameTextFormFieldFinder = find.byType(TextFormField).at(0);
final memMemoTextFormFieldFinder = find.byType(TextFormField).at(1);
final saveFabFinder = find.byIcon(Icons.save_alt).at(0);

TextFormField memNameTextFormField(WidgetTester widgetTester) =>
    (widgetTester.widget(memNameTextFormFieldFinder) as TextFormField);

Future<void> prepareSavedData(
  String memName,
  String memMemo, {
  bool isArchived = false,
}) async {
  final database = await DatabaseManager().open(app.databaseDefinition);
  final memTable = database.getTable(memTableDefinition.name);
  final savedMemId = await memTable.insert({
    memNameColumnName: memName,
    createdAtColumnName: DateTime.now(),
    archivedAtColumnName: isArchived ? DateTime.now() : null,
  });
  assert(savedMemId == 1);
  final memItemTable = database.getTable(memItemTableDefinition.name);
  await memItemTable.insert({
    memIdColumnName: savedMemId,
    memItemTypeColumnName: MemItemType.memo.name,
    memItemValueColumnName: memMemo,
    createdAtColumnName: DateTime.now(),
    archivedAtColumnName: isArchived ? DateTime.now() : null,
  });
  await DatabaseManager().close(app.databaseDefinition.name);
}
