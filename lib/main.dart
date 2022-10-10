import 'package:flutter/material.dart';
import 'package:mem/app.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

final databaseDefinition = DefD(
  'mem.db',
  4,
  [
    memTableDefinition,
    memItemTableDefinition,
  ],
);

Future<void> main({String? languageCode}) async {
  await openDatabase();

  runApp(MemApplication(languageCode));
}

Future<Database> openDatabase() => t(
      {},
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        final database = await DatabaseManager().open(databaseDefinition);

        MemRepository(
          database.getTable(memTableDefinition.name),
        );
        MemItemRepository(
          database.getTable(memItemTableDefinition.name),
        );

        return database;
      },
    );
