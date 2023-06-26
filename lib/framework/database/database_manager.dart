import 'package:flutter/foundation.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/framework/database/definitions/definition.dart';
import 'package:mem/framework/database/indexed_database.dart';
import 'package:mem/framework/database/sqlite_database.dart';
import 'package:mem/logger/log_service.dart';

// FIXME Managerであることが分からない実装にしたい
// 具体的には、Databaseクラスのfactoryだけで完結させたい
class DatabaseManager {
  // FIXME Managerがテスト中かどうかを保持するのは正しいか？
  final bool _onTest;
  final _databases = <String, Database>{};

  Future<Database> open(
    DatabaseDefinition definition,
  ) =>
      i(
        () async {
          // FIXME ログの出し方が気持ち悪い
          final dbName = info(_dbName(definition.name));
          definition = DatabaseDefinition(
              dbName, definition.version, definition.tableDefinitions);

          if (_databases.containsKey(dbName)) {
            warn('Database: $dbName is opened.');
          } else {
            final database = await (kIsWeb
                    ?
                    // WEBでテストするときにカバレッジを計測する方法がないため
                    IndexedDatabase(definition) // coverage:ignore-line
                    : SqliteDatabase(definition))
                .open();
            _databases.putIfAbsent(dbName, () => database);
          }
          return _databases[dbName]!;
        },
        {'definition': definition},
      );

  Future<bool> close(String name) => i(
        () async {
          final dbName = _dbName(name);
          if (_databases.containsKey(dbName)) {
            info('Close database. name: $dbName');
            final closeResult = await _databases[dbName]!.close();
            _databases.remove(dbName);
            return closeResult;
          } else {
            warn('I do not have database. name: $dbName');
            return false;
          }
        },
        {'name': _dbName(name)},
      );

  Future<bool> delete(String name) => i(
        () async {
          final dbName = _dbName(name);
          if (_databases.containsKey(dbName)) {
            info('Delete database. name: $dbName');
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
        {'name': _dbName(name)},
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
