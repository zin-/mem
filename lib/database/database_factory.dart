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
              ? IndexedDatabase(definition) // coverage:ignore-line
              // WEBでテストするときにカバレッジを取得する方法がないため
              : SqliteDatabase(definition))
          .open();
      _databases.putIfAbsent(definition.name, () => database);
    }
    return _databases[definition.name]!;
  }

  Future<bool> close(String name) async {
    if (_databases.containsKey(name)) {
      print('Close database. name: $name');
      final closeResult = await _databases[name]!.close();
      _databases.remove(name);
      return closeResult;
    } else {
      print('I do not have database. name: $name');
      return false;
    }
  }

  Future<bool> delete(String name) async {
    if (_databases.containsKey(name)) {
      print('Delete database. name: $name');
      final deleteResult = await _databases[name]!.delete();
      if (deleteResult) {
        _databases.remove(name);
        return true;
      } else {
        return false;
      }
    } else {
      print('I do not have database. name: $name');
      return false;
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
