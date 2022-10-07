import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/domains/mem.dart';
import 'package:mem/services/mem_service.dart';

// FIXME integration testでrepositoryを参照するのはNG
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

class TestSize {
  static const small = 'Small';
  static const medium = 'Medium';

  TestSize._();
}

const defaultDuration = Duration(seconds: 1);

Future clearDatabase() async {
  // FIXME openしないとdeleteできないのは、実際のDatabaseと挙動が異なる
  // 今の実装だと難しいっぽい。いつかチャレンジする
  await DatabaseManager().open(app.databaseDefinition);
  await DatabaseManager().delete(app.databaseDefinition.name);

  MemRepository.reset(null);
  MemItemRepository.reset(null);

  MemService.reset(null);
}

Future<void> pumpApplication({String? languageCode}) =>
    app.main(languageCode: languageCode);

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
