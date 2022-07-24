import 'package:flutter/material.dart';

import 'package:mem/app.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';

void main() async {
  await _openDatabase();

  runApp(const MemApplication());
}

Future<DatabaseV2> _openDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await DatabaseManager.open(DefD(
    'mem.db',
    1,
    [],
  ));

  return database;
}
