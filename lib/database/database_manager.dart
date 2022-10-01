import 'package:flutter/foundation.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';
import 'package:mem/logger.dart';

class DatabaseManager {
  final bool _onTest;
  final _databases = <String, Database>{};

  Future<Database> open(
    DatabaseDefinition definition,
  ) =>
      t(
        {'definition': definition, 'name': _dbName(definition.name)},
        () async {
          final dbName = _dbName(definition.name);
          final dbDefinition =
              DefD(dbName, definition.version, definition.tableDefinitions);

          if (_databases.containsKey(dbName)) {
            warn('Database: $dbName is opened.');
          } else {
            trace('Open database. name: $dbName');
            final database = await (kIsWeb
                    ? IndexedDatabase(dbDefinition) // coverage:ignore-line
                    // WEBでテストするときにカバレッジを取得する方法がないため
                    : SqliteDatabase(dbDefinition))
                .open();
            _databases.putIfAbsent(dbName, () => database);
          }
          return _databases[dbName]!;
        },
      );

  Future<bool> close(String name) => t(
        {'name': _dbName(name)},
        () async {
          final dbName = _dbName(name);
          if (_databases.containsKey(dbName)) {
            trace('Close database. name: $dbName');
            final closeResult = await _databases[dbName]!.close();
            _databases.remove(dbName);
            return closeResult;
          } else {
            warn('I do not have database. name: $dbName');
            return false;
          }
        },
      );

  Future<bool> delete(String name) => t(
        {'name': _dbName(name)},
        () async {
          final dbName = _dbName(name);
          if (_databases.containsKey(dbName)) {
            trace('Delete database. name: $dbName');
            final deleteResult = await _databases[dbName]!.delete();
            if (deleteResult) {
              _databases.remove(dbName);
              return true;
            } else {
              return false;
            }
          } else {
            warn('I do not have database. name: $dbName');
            return false;
          }
        },
      );

  String _dbName(name) => _onTest ? 'test-$name' : name;

  DatabaseManager._(this._onTest);

  static DatabaseManager? _instance;

  factory DatabaseManager({bool onTest = false}) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = DatabaseManager._(onTest);
      _instance = tmp;
    }
    return tmp;
  }
}
