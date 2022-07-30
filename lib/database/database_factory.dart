import 'package:flutter/foundation.dart';

import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';
import 'package:mem/logger.dart';

class DatabaseManager {
  final _databases = <String, Database>{};

  Future<Database> open(
    DatabaseDefinition definition,
  ) =>
      v(
        {'definition': definition},
        () async {
          if (_databases.containsKey(definition.name)) {
            warn('Database: ${definition.name} is opened.');
          } else {
            trace('Open database. name: ${definition.name}');
            final database = await (kIsWeb
                    ? IndexedDatabase(definition) // coverage:ignore-line
                    // WEBでテストするときにカバレッジを取得する方法がないため
                    : SqliteDatabase(definition))
                .open();
            _databases.putIfAbsent(definition.name, () => database);
          }
          return _databases[definition.name]!;
        },
      );

  Future<bool> close(String name) async {
    if (_databases.containsKey(name)) {
      trace('Close database. name: $name');
      final closeResult = await _databases[name]!.close();
      _databases.remove(name);
      return closeResult;
    } else {
      warn('I do not have database. name: $name');
      return false;
    }
  }

  Future<bool> delete(String name) async {
    if (_databases.containsKey(name)) {
      trace('Delete database. name: $name');
      final deleteResult = await _databases[name]!.delete();
      if (deleteResult) {
        _databases.remove(name);
        return true;
      } else {
        return false;
      }
    } else {
      warn('I do not have database. name: $name');
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
