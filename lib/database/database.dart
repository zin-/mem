import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart' as idb_browser;
import 'package:idb_shim/idb.dart' as idb_shim;

class OldDatabase {
  final String name;
  final int version;
  final List<TableDefinition> tables;

  static Future<void> delete(String name) async {
    if (kIsWeb) {
      var factory = idb_browser.getIdbFactory();
      factory?.deleteDatabase(name);
    } else {
      final path = await _getDatabasePath(name);
      if (Platform.isAndroid) {
        if (await sqflite.databaseExists(path)) {
          sqflite.deleteDatabase(path);
        } else {
          print('Database does not exist. path: $path');
        }
      } else if (Platform.isWindows) {
        var databaseFactory = sqflite_ffi.databaseFactoryFfi;
        databaseFactory.deleteDatabase(path);
      }
    }
  }

  static Future<OldDatabase> open(
    String name,
    int version,
    List<TableDefinition> tables,
  ) async =>
      await OldDatabase._(name, version, tables)._open();

  OldDatabase._(this.name, this.version, this.tables);

  late final sqflite.Database _database;
  late final idb_shim.Database _idb;

  Future<OldDatabase> _open() async {
    if (kIsWeb) {
      print('Platform is web');

      var factory = idb_browser.getIdbFactory()!;
      _idb = await factory.open(
        name,
        version: version,
        onUpgradeNeeded: (event) {
          for (var table in tables) {
            event.database.createObjectStore(table.name, autoIncrement: true);
          }
        },
      );
    } else {
      print('Platform is ${Platform.operatingSystem}');

      final path = await _getDatabasePath(name);
      if (Platform.isAndroid) {
        _database = await sqflite.openDatabase(
          path,
          version: version,
          onCreate: (db, version) => _onCreate(db, version, tables),
        );
      } else if (Platform.isWindows) {
        var databaseFactory = sqflite_ffi.databaseFactoryFfi;
        _database = await databaseFactory.openDatabase(
          path,
          options: sqflite.OpenDatabaseOptions(
            version: version,
            onCreate: (db, version) => _onCreate(db, version, tables),
          ),
        );
      }
    }

    return this;
  }

  _onCreate(sqflite.Database db, int version, List<TableDefinition> tables) {
    for (var table in tables) {
      db.execute(table.buildCreateSql());
    }
  }

  static Future<String> _getDatabasePath(String name) async {
    print('Platform is ${Platform.operatingSystem}');

    late final String directoryPath;
    if (Platform.isAndroid) {
      directoryPath = await sqflite.getDatabasesPath();
    } else if (Platform.isWindows) {
      sqflite_ffi.sqfliteFfiInit();
      final directory = await path_provider.getApplicationSupportDirectory();
      directoryPath = directory.path;
    } else {
      throw DatabaseException(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
    }

    return path.join(directoryPath, name);
  }
}

typedef DefT = TableDefinition;

class TableDefinition {
  final String name;
  final List<FieldDefinition> fields;

  TableDefinition(this.name, this.fields) {
    if (name.isEmpty) {
      throw DatabaseException('Table name is required.');
    } else if (fields.isEmpty) {
      throw DatabaseException('Table fields are required.');
    } else if (fields.whereType<PrimaryKeyDefinition>().isEmpty) {
      throw DatabaseException('Primary key is required.');
    } else if (fields.whereType<PrimaryKeyDefinition>().length > 1) {
      throw DatabaseException('Only one primary key is allowed.');
    }
  }

  Future<int> insert(OldDatabase database, Map<String, dynamic> values) async {
    if (kIsWeb) {
      final txn = database._idb.transaction(name, idb_shim.idbModeReadWrite);
      final store = txn.objectStore(name);
      final added = await store.add(values);
      await store.put(values..putIfAbsent('id', () => added), added);
      await txn.completed;
      return int.parse(added.toString());
    } else {
      return database._database.insert(name, values);
    }
  }

  Future<List<Map<String, dynamic>>> select(OldDatabase database) async {
    if (kIsWeb) {
      final txn = database._idb.transaction(name, idb_shim.idbModeReadOnly);
      final objects = await txn.objectStore(name).getAll();
      await txn.completed;
      return objects.map((object) {
        final json = jsonDecode(jsonEncode(object));
        return Map.fromEntries(
            fields.map((f) => MapEntry(f.name, json[f.name])));
      }).toList();
    }
    return database._database.query(name);
  }

  Future<Map<String, dynamic>> selectById(
    OldDatabase database,
    dynamic id,
  ) async {
    if (kIsWeb) {
      final txn = database._idb.transaction(name, idb_shim.idbModeReadOnly);
      final object = await txn.objectStore(name).getObject(id);
      await txn.completed;
      final json = jsonDecode(jsonEncode(object));
      return Map.fromEntries(fields.map((f) => MapEntry(f.name, json[f.name])));
    }
    return (await database._database.query(
      name,
      where: 'id = ?',
      whereArgs: [id],
    ))[0];
  }

  Future<int> update(
    OldDatabase database,
    Map<String, dynamic> values,
    Map<String, dynamic> where,
  ) async {
    if (kIsWeb) {
      final txn = database._idb.transaction(name, idb_shim.idbModeReadWrite);
      final store = txn.objectStore(name);
      final put = await store.put(values, where['id']);
      await txn.completed;
      return int.parse(put.toString());
    }
    return database._database.update(
      name,
      values,
      where: where.keys.map((key) => '$key = ?').join(', '),
      whereArgs: where.values.toList(),
    );
  }

  Future<int> delete(
    OldDatabase database,
    Map<String, dynamic> where,
  ) async {
    if (kIsWeb) {
      final txn = database._idb.transaction(name, idb_shim.idbModeReadWrite);
      final store = txn.objectStore(name);
      await store.delete(where['id']);
      await txn.completed;
      return 1;
    }
    return database._database.delete(
      name,
      where: where.keys.map((key) => '$key = ?').join(', '),
      whereArgs: where.values.toList(),
    );
  }

  @override
  String toString() => 'Database table definition: $name';

  String buildCreateSql() => 'CREATE TABLE'
      ' $name'
      ' ('
      ' ${fields.map((field) => field.buildFieldSql()).join(', ')}'
      ' )';
}

typedef DefF = FieldDefinition;

class FieldDefinition {
  final String name;
  final FieldType type;

  FieldDefinition(this.name, this.type);

  String buildFieldSql() => '$name ${type.value}';
}

typedef DefPK = PrimaryKeyDefinition;

class PrimaryKeyDefinition extends FieldDefinition {
  final bool autoincrement;

  PrimaryKeyDefinition(
    super.name,
    super.type, {
    this.autoincrement = false,
  });

  @override
  String buildFieldSql() => '${super.buildFieldSql()}'
      ' PRIMARY KEY'
      '${autoincrement ? ' AUTOINCREMENT' : ''}';
}

typedef TypeF = FieldType;

enum FieldType { integer, text }

extension on FieldType {
  static final values = {FieldType.integer: 'INTEGER', FieldType.text: 'TEXT'};

  String get value => values[this]!;
}

class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);
}
