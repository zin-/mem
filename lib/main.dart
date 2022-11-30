import 'package:flutter/material.dart';
import 'package:mem/acts/act_entity.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/database/i/types.dart';
import 'package:mem/gui/app.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

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
  WidgetsFlutterBinding.ensureInitialized();

  initializeLogger();

  await openDatabase();

  runApp(MemApplication(languageCode));
}

Future<Database> openDatabase() async {
  final database = await DatabaseManager().open(databaseDefinition);

  MemRepository(
    database.getTable(memTableDefinition.name),
  );
  MemItemRepository(
    database.getTable(memItemTableDefinition.name),
  );
  ActRepository(
    database.getTable(actTableDefinition.name),
  );

  return database;
}
