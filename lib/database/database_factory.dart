import 'package:flutter/foundation.dart';

import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';

class DatabaseManager {
  DatabaseManager._();

  static final _databases = <String, DatabaseV2>{};

  static Future<DatabaseV2> open(
    DatabaseDefinition definition,
  ) async {
    if (_databases.containsKey(definition.name)) {
      print('Database: ${definition.name} is opened.');
    } else {
      print('Open database. name: ${definition.name}');
      final database = await (kIsWeb
              ? IndexedDatabaseV2(definition)
              : SqliteDatabaseV2(definition))
          .open();
      _databases.putIfAbsent(definition.name, () => database);
    }
    return _databases[definition.name]!;
  }

  static Future<void> delete(String name) async {
    if (_databases.containsKey(name)) {
      print('Delete database. name: $name');
      await _databases[name]!.delete();
      _databases.remove(name);
    } else {
      print('I do not have database. name: $name');
    }
  }
}

abstract class DatabaseFactory {
  static Future<Database> open(
    String name,
    int version,
    List<TableDefinition> tables,
  ) async =>
      await (kIsWeb
              ? IndexedDatabase(name, version, tables)
              : SqliteDatabase(name, version, tables))
          .open();
}
