import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';

class SqliteDatabase extends Database {
  SqliteDatabase(super.definition) {
    _initialize();
  }

  late final sqflite.DatabaseFactory _factory;
  late final Future<String> _pathFuture;
  late final sqflite.Database _database;

  @override
  Future<Database> open() async {
    _database = await _factory.openDatabase(
      await _pathFuture,
      options: sqflite.OpenDatabaseOptions(
        version: definition.version,
        onCreate: (db, version) async {
          print('Create Database. $definition }');
          for (var tableDefinition in definition.tableDefinitions) {
            print('Create table. $tableDefinition');
            await db.execute(tableDefinition.buildCreateTableSql());
          }
        },
      ),
    );

    for (var tableDefinition in definition.tableDefinitions) {
      tables.putIfAbsent(
        tableDefinition.name,
        () => SqliteTable(tableDefinition, _database),
      );
    }

    return this;
  }

  @override
  Future<bool> delete() async {
    if (await _factory.databaseExists(await _pathFuture)) {
      await _factory.deleteDatabase(await _pathFuture);
      return true;
    } else {
      print(
        'Delete failed.'
        ' Database does not exist.'
        ' databasePath: $_pathFuture',
      );
      return false;
    }
  }

  void _initialize() {
    if (kIsWeb) throw DatabaseException('Unsupported platform. Platform: Web');

    Future<String> databaseDirectoryPath;
    if (Platform.isAndroid) {
      _factory = sqflite.databaseFactory;
      databaseDirectoryPath = sqflite.getDatabasesPath();
    } else if (Platform.isWindows) {
      sqflite_ffi.sqfliteFfiInit();
      _factory = sqflite_ffi.databaseFactoryFfi;
      databaseDirectoryPath =
          getApplicationSupportDirectory().then((value) => value.path);
    } else {
      throw DatabaseException(
          'Unsupported platform. platform: ${Platform.operatingSystem}');
    }
    _pathFuture = databaseDirectoryPath
        .then((value) => path.join(value, definition.name));
  }
}

class SqliteTable extends Table {
  final sqflite.Database _database;

  SqliteTable(super.definition, this._database);

  @override
  Future<int> insert(Map<String, dynamic> value) =>
      _database.insert(definition.name, convertTo(value));

  @override
  Future<List<Map<String, dynamic>>> select() async =>
      (await _database.query(definition.name))
          .map((e) => convertFrom(e))
          .toList();

  @override
  Future<Map<String, dynamic>> selectByPk(pk) async =>
      convertFrom((await _database.query(
        definition.name,
        where: _buildWhereId(),
        whereArgs: [pk],
      ))
          .first);

  @override
  Future<int> updateByPk(pk, Map<String, dynamic> value) => _database.update(
        definition.name,
        convertTo(value),
        where: _buildWhereId(),
        whereArgs: [pk],
      );

  @override
  Future<int> deleteByPk(pk) => _database.delete(
        definition.name,
        where: _buildWhereId(),
        whereArgs: [pk],
      );

  @override
  Future<int> delete() => _database.delete(definition.name);

  String _buildWhereId() =>
      '${definition.columns.whereType<DefPK>().first.name} = ?';
}
