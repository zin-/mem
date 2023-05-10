import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_items_view.dart';
import 'package:mem/mems/mem_name.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/mems/mem_service.dart';

// FIXME integration testでrepositoryを参照するのはNG
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';
import 'package:mem/repositories/mem_item_repository.dart';

const defaultDuration = Duration(seconds: 1);

Future clearDatabase() async {
  // FIXME openしないとdeleteできないのは、実際のDatabaseと挙動が異なる
  // 今の実装だと難しいっぽい。いつかチャレンジする
  await DatabaseManager(onTest: true).open(app.databaseDefinition);
  await DatabaseManager(onTest: true).delete(app.databaseDefinition.name);

  MemRepository.resetWith(null);
  MemItemRepository.resetWith(null);

  MemService.reset(null);
}

Future<void> runApplication({String? languageCode}) =>
    app.main(languageCode: languageCode);

final memListFilterButton = find.byIcon(Icons.filter_list);
final findShowNotArchiveSwitch = find.byType(Switch).at(0);
final findShowArchiveSwitch = find.byType(Switch).at(1);

Future closeMemListFilter(WidgetTester widgetTester) async {
  await widgetTester.tapAt(const Offset(0, 0));
  await widgetTester.pumpAndSettle(defaultDuration);
}

TextFormField memNameTextFormField(WidgetTester widgetTester) =>
    (widgetTester.widget(memNameTextFormFieldFinder) as TextFormField);

Future<void> prepareSavedData(
  String memName,
  String memMemo, {
  bool isArchived = false,
}) async {
  final database =
      await DatabaseManager(onTest: true).open(app.databaseDefinition);
  final memTable = database.getTable(memTableDefinition.name);
  final savedMemId = await memTable.insert({
    defMemName.name: memName,
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
  await DatabaseManager(onTest: true).close(app.databaseDefinition.name);
}

// V2
/// enum型では文字列を返却することができないためclassで定義する
/// ref.
/// - https://testing.googleblog.com/2010/12/test-sizes.html
/// 現状では利用していないが、外部システムとの連携を行うように機能拡張した場合に必要となるため定義しておく
/// （YAGNIの原則に反するが採用したい概念のため許容する）
abstract class TestSize {
  /// 他システムへの依存が排除されたテスト
  /// 単一のランタイムで実行可能
  ///
  /// e.g.
  /// - Database(local), File system, System property access禁止
  /// - Multi thread, Sleep statement禁止
  static const small = 'Small';

  /// プラットフォーム外への依存が排除されたテスト
  /// 単一のプラットフォームで実行可能
  ///
  /// e.g.
  /// - Local Database, File system, System property access許可
  /// - Multi thread, Sleep statement許可
  /// - View element許可
  static const medium = 'Medium';

  /// すべての依存を排除しないテスト
  ///
  /// e.g.
  /// - External system, Database, Network access許可
  static const large = 'Large';

  TestSize._();
}

final newMemFabFinder = find.byIcon(Icons.add);
final memNameTextFormFieldFinder = find.descendant(
  of: find.byType(MemNameTextFormField),
  matching: find.byType(TextFormField),
);
final memMemoTextFormFieldFinder = find.descendant(
  of: find.byType(MemItemsViewComponent),
  matching: find.byType(TextFormField),
);
final saveMemFabFinder = find.byIcon(Icons.save_alt);
final okFinder = find.text('OK');

Future<void> prepareSavedMem(
  String memName,
  DateTime memNotifyOn,
  TimeOfDay memNotifyAt,
) async {
  final memTable =
      (await DatabaseManager(onTest: true).open(app.databaseDefinition))
          .getTable(memTableDefinition.name);

  await MemRepository(memTable).receive(Mem(
      name: memName,
      id: null,
      period: DateAndTimePeriod(
        start: DateAndTime(
          memNotifyOn.year,
          memNotifyOn.month,
          memNotifyOn.day,
          memNotifyAt.hour,
          memNotifyAt.minute,
        ),
      )));

  await DatabaseManager(onTest: true).close(app.databaseDefinition.name);

  MemRepository.resetWith(null);
}

Future<void> runTestWidget(WidgetTester widgetTester, Widget widget) =>
    widgetTester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        onGenerateTitle: (context) => L10n(context).test(),
        home: widget,
      ),
    );
