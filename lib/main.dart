import 'package:flutter/material.dart';
import 'package:mem/act_counter/act_counter_configure.dart';
import 'package:mem/act_counter/all.dart';
import 'package:mem/acts/act_entity.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/database/i/types.dart';
import 'package:mem/gui/app.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_list_page.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/repositories/mem_entity.dart';
import 'package:mem/repositories/mem_item_repository.dart';

import 'logger/i/api.dart';

final databaseDefinition = DefD(
  'mem.db',
  5,
  [
    memTableDefinition,
    memItemTableDefinition,
    actTableDefinition,
  ],
);

Future<void> main({String? languageCode}) async {
  run(MemListPage(), languageCode: languageCode);
}

@pragma('vm:entry-point')
launchActCounterConfigure() async {
  run(const ActCounterConfigure());
}

Future<void> run(Widget home, {String? languageCode}) async {
  WidgetsFlutterBinding.ensureInitialized();

  initializeLogger();
  await openDatabase();
  initializeActCounter();

  checkForWidgetLaunch();
  sendData();

  runApp(MemApplication(home, languageCode));
}

Future<Database> openDatabase() async {
  final database = await DatabaseManager().open(databaseDefinition);

  MemRepositoryV2(
    database.getTable(memTableDefinition.name),
  );
  MemItemRepositoryV2(
    database.getTable(memItemTableDefinition.name),
  );
  ActRepository(
    database.getTable(actTableDefinition.name),
  );

  return database;
}
