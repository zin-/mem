import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/core/mem.dart';
import 'package:mem/mems/mem_items_view.dart';
import 'package:mem/mems/mem_name.dart';
import 'package:mem/mems/mem_notify_at.dart';
import 'package:mem/mems/mem_service.dart';
import 'package:mem/gui/date_and_time_text_form_field.dart';

// FIXME integration testでrepositoryを参照するのはNG
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

const defaultDuration = Duration(seconds: 1);

Future clearDatabase() async {
  // FIXME openしないとdeleteできないのは、実際のDatabaseと挙動が異なる
  // 今の実装だと難しいっぽい。いつかチャレンジする
  await DatabaseManager(onTest: true).open(app.databaseDefinition);
  await DatabaseManager(onTest: true).delete(app.databaseDefinition.name);

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
  await DatabaseManager(onTest: true).close(app.databaseDefinition.name);
}

// V2
class TestSize {
  static const small = 'Small';
  static const medium = 'Medium';

  TestSize._();
}

Future<void> runApplication() => app.main(languageCode: 'en');

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
final showDatePickerIconFinder = find.descendant(
  of: find.byType(DateAndTimeTextFormField),
  matching: find.byIcon(Icons.calendar_month),
);
final okFinder = find.text('OK');
final allDaySwitchFinder = find.descendant(
  of: find.byType(DateAndTimeTextFormField),
  matching: find.byType(Switch),
);
final showTimePickerIconFinder = find.descendant(
  of: find.byType(DateAndTimeTextFormField),
  matching: find.byIcon(Icons.access_time_outlined),
);
final clearDateAndTimeIconFinder = find.descendant(
  of: find.byType(DateAndTimeTextFormField),
  matching: find.byIcon(Icons.clear),
);
final memNotifyAtTextFinder = find.byType(MemNotifyAtText);

Future<void> prepareSavedMem(
  String memName,
  DateTime memNotifyOn,
  TimeOfDay memNotifyAt,
) async {
  final memTable =
      (await DatabaseManager(onTest: true).open(app.databaseDefinition))
          .getTable(memTableDefinition.name);

  await MemRepository(memTable).receive(MemEntity(
    name: memName,
    id: null,
    notifyOn: memNotifyOn,
    notifyAt: memNotifyOn.add(Duration(
      hours: memNotifyAt.hour,
      minutes: memNotifyAt.minute,
    )),
  ));

  await DatabaseManager(onTest: true).close(app.databaseDefinition.name);

  MemRepository.reset(null);
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
