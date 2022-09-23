import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/logger.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/repositories/repository.dart';

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

  group('Basic scenario', () {
    testWidgets(
      ': create',
      (widgetTester) async {
        await app.main();
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.tap(showNewMemFabFinder);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        const enteringMemName = 'entering mem name';
        const enteringMemMemo = 'entering mem memo';

        await widgetTester.enterText(
            memNameTextFormFieldFinder, enteringMemName);
        await widgetTester.enterText(
            memMemoTextFormFieldFinder, enteringMemMemo);

        await widgetTester.tap(saveFabFinder);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.pageBack();
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

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

        await app.main();
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.tap(find.text(savedMemName));
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        const enteringMemName = 'entering mem name';
        const enteringMemMemo = 'entering mem memo';

        await widgetTester.enterText(
            memNameTextFormFieldFinder, enteringMemName);
        await widgetTester.enterText(
            memMemoTextFormFieldFinder, enteringMemMemo);

        await widgetTester.tap(saveFabFinder);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

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

        await app.main();
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.tap(find.text(savedMemName));
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.tap(find.byIcon(Icons.archive));
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        expect(
          find.descendant(
            of: find.byType(Text),
            matching: find.text(savedMemName),
          ),
          findsNothing,
        );

        await widgetTester.tap(memListFilterButton);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));
        await widgetTester.tap(findShowArchiveSwitch);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

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

        await app.main();
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.tap(memListFilterButton);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));
        await widgetTester.tap(findShowArchiveSwitch);
        await widgetTester.tap(findShowNotArchiveSwitch);
        await closeMemListFilter(widgetTester);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.tap(find.text(savedMemName));
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.tap(find.byIcon(Icons.unarchive));
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.pageBack();
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text(savedMemName), findsNothing);

        await widgetTester.tap(memListFilterButton);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));
        await widgetTester.tap(findShowNotArchiveSwitch);
        await closeMemListFilter(widgetTester);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

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

        await app.main();
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.tap(find.text(savedMemName));
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.tap(memDetailMenuButtonFinder);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));
        await widgetTester.tap(removeButtonFinder);
        await widgetTester.pump();
        await widgetTester.tap(okButtonFinder);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text(savedMemName), findsNothing);

        await widgetTester.tap(memListFilterButton);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));
        await widgetTester.tap(findShowArchiveSwitch);
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));
        await closeMemListFilter(widgetTester);

        expect(find.text(savedMemName), findsNothing);
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

        await app.main();
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.tap(find.text(savedMemName));
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.text(savedMemName), findsOneWidget);
        expect(widgetTester.widgetList(find.byType(TextFormField)).length, 2);
      },
      tags: 'Medium',
    );
  });
}

final memListFinder = find.byType(CustomScrollView);
final memListTileFinder = find.descendant(
  of: memListFinder,
  matching: find.byType(ListTile),
);
final showNewMemFabFinder = find.byType(FloatingActionButton);

Finder findMemNameTextOnListAt(int index) => find.descendant(
      of: memListTileFinder.at(index),
      matching: find.byType(Text),
    );

Text getMemNameTextOnListAt(WidgetTester widgetTester, int index) =>
    widgetTester.widget(findMemNameTextOnListAt(index)) as Text;

void expectMemNameTextOnListAt(
  WidgetTester widgetTester,
  int index,
  String memName,
) =>
    expect(
      getMemNameTextOnListAt(widgetTester, index).data,
      memName,
    );

final memListFilterButton = find.byIcon(Icons.filter_list);
final findShowNotArchiveSwitch = find.byType(Switch).at(0);
final findShowArchiveSwitch = find.byType(Switch).at(1);

Future closeMemListFilter(WidgetTester widgetTester) async {
  await widgetTester.tapAt(const Offset(0, 0));
  await widgetTester.pumpAndSettle(const Duration(seconds: 1));
}

final memNameTextFormFieldFinder = find.byType(TextFormField).at(0);
final memMemoTextFormFieldFinder = find.byType(TextFormField).at(1);
final saveFabFinder = find.byIcon(Icons.save_alt).at(0);
final appBarFinder = find.byType(AppBar);

TextFormField memNameTextFormField(WidgetTester widgetTester) =>
    (widgetTester.widget(memNameTextFormFieldFinder) as TextFormField);

void expectMemNameOnMemDetail(
  WidgetTester widgetTester,
  String memName,
) =>
    expect(
      memNameTextFormField(widgetTester).initialValue,
      memName,
    );

final memDetailMenuButtonFinder = find.descendant(
  of: appBarFinder,
  matching: find.byIcon(Icons.more_vert),
);

Future<void> showRemoveMemConfirmDialog(WidgetTester widgetTester) async {
  await widgetTester.tap(memDetailMenuButtonFinder);
  await widgetTester.pumpAndSettle(const Duration(seconds: 1));

  await widgetTester.tap(removeButtonFinder);
  await widgetTester.pump();
}

final removeButtonFinder = find.byIcon(Icons.delete);
final removeConfirmationFinder = find.text('Can I remove this?');
final undoButtonFinder = find.text('Undo');
final cancelButtonFinder = find.text('Cancel');
final okButtonFinder = find.text('OK');

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
