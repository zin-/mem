import 'package:flutter/material.dart';
import 'package:mem/app.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

final databaseDefinition = DefD(
  'mem.db',
  3,
  [
    memTableDefinition,
    memItemTableDefinition,
  ],
);

Future<void> main({String? languageCode}) => t(
      {},
      () async {
        await _openDatabase();

        runApp(MemApplication(languageCode));
      },
    );

Future<Database> _openDatabase() => t(
      {},
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        final database = await DatabaseManager().open(databaseDefinition);

        MemRepository.initialize(database.getTable(memTableDefinition.name));
        MemItemRepository.initialize(
            database.getTable(memItemTableDefinition.name));

        return database;
      },
    );
