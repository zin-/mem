import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/database/definition.dart';
import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mem_items.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/mems/mem_service.dart';

import 'scenarios/helpers.dart';

const defaultDuration = Duration(seconds: 1);

Future clearDatabase() async {
  // FIXME openしないとdeleteできないのは、実際のDatabaseと挙動が異なる
  // 今の実装だと難しいっぽい。いつかチャレンジする
  await DatabaseManager(onTest: true).open(databaseDefinition);
  await DatabaseManager(onTest: true).delete(databaseDefinition.name);

  MemRepository.resetWith(null);
  MemItemRepository.resetWith(null);

  MemService.reset(null);
}

final memListFilterButton = find.byIcon(Icons.filter_list);
final findShowNotArchiveSwitch = find.byType(Switch).at(0);
final findShowArchiveSwitch = find.byType(Switch).at(1);

Future closeMemListFilter(WidgetTester widgetTester) async {
  await widgetTester.tapAt(const Offset(0, 0));
  await widgetTester.pumpAndSettle(defaultDuration);
}

TextFormField memNameTextFormField(WidgetTester widgetTester) =>
    (widgetTester.widget(memNameOnDetailPageFinder) as TextFormField);

Future<void> prepareSavedData(
  String memName,
  String memMemo, {
  bool isArchived = false,
}) async {
  final database = await DatabaseManager(onTest: true).open(databaseDefinition);
  final memTable = database.getTable(memTableDefinition.name);
  final savedMemId = await memTable.insert({
    defMemName.name: memName,
    createdAtColDef.name: DateTime.now(),
    archivedAtColDef.name: isArchived ? DateTime.now() : null,
  });
  assert(savedMemId == 1);
  final memItemTable = database.getTable(memItemTableDefinition.name);
  await memItemTable.insert({
    memIdFkDef.name: savedMemId,
    memItemTypeColDef.name: MemItemType.memo.name,
    memItemValueColDef.name: memMemo,
    createdAtColDef.name: DateTime.now(),
    archivedAtColDef.name: isArchived ? DateTime.now() : null,
  });
  await DatabaseManager(onTest: true).close(databaseDefinition.name);
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

Future<void> prepareSavedMem(
  String memName,
  DateTime memNotifyOn,
  TimeOfDay memNotifyAt,
) async {
  final memTable =
      (await DatabaseManager(onTest: true).open(databaseDefinition))
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

  await DatabaseManager(onTest: true).close(databaseDefinition.name);

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
