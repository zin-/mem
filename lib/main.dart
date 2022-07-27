import 'package:flutter/material.dart';

import 'package:mem/app.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/repositories/mem_repository.dart';

final databaseDefinition = DefD(
  'mem.db',
  1,
  [
    memTable,
  ],
);

void main() async {
  await _openDatabase();

  runApp(const MemApplication());
}

Future<Database> _openDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await DatabaseManager().open(databaseDefinition);

  MemRepository.initialize(database.getTable(memTable.name));

  return database;
}
