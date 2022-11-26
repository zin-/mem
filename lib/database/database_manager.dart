import 'package:flutter/foundation.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';
import 'package:mem/logger/i/api.dart';

// FIXME Managerであることが分からない実装にしたい
// 具体的には、Databaseクラスのfactoryだけで完結させたい
class DatabaseManager {
  // FIXME Managerがテスト中かどうかを保持するのは正しいか？
  final bool _onTest;
  final _databases = <String, Database>{};

  Future<Database> open(
    DatabaseDefinition definition,
  ) =>
      t(
        {'definition': definition},
        () async {
          // FIXME ログの出し方が気持ち悪い
          final dbName = trace(_dbName(definition.name));
          definition = DatabaseDefinition(
              dbName, definition.version, definition.tableDefinitions);

          if (_databases.containsKey(dbName)) {
            warn('Database: $dbName is opened.');
          } else {
            final database = await (kIsWeb
                    ? IndexedDatabase(definition) // coverage:ignore-line
                    // WEBでテストするときにカバレッジを取得する方法がないため
                    : SqliteDatabase(definition))
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
