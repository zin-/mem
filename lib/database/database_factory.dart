import 'package:flutter/foundation.dart';

import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';

class DatabaseManager {
  final _databases = <String, Database>{};

  Future<Database> open(
    DatabaseDefinition definition,
  ) async {
    if (_databases.containsKey(definition.name)) {
      print('Database: ${definition.name} is opened.');
    } else {
      print('Open database. name: ${definition.name}');
      final database = await (kIsWeb
              ? IndexedDatabase(definition)
              : SqliteDatabase(definition))
          .open();
      _databases.putIfAbsent(definition.name, () => database);
    }
    return _databases[definition.name]!;
  }

  Future<void> delete(String name) async {
    if (_databases.containsKey(name)) {
      print('Delete database. name: $name');
      await _databases[name]!.delete();
      _databases.remove(name);
    } else {
      print('I do not have database. name: $name');
    }
  }

  DatabaseManager._();

  static DatabaseManager? _instance;

  factory DatabaseManager() {
    var tmp = _instance;
    if (tmp == null) {
      tmp = DatabaseManager._();
      _instance = tmp;
    }
    return tmp;
  }
}
