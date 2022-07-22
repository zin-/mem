import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

import 'package:mem/database/database.dart';

class SqliteDatabase extends Database {
  SqliteDatabase(String name, int version, List<DefT> tables)
      : super(name, version, tables) {
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
        version: version,
        onCreate: (db, version) => _onCreate(db, version, tables),
      ),
    );

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

  @override
  Future<int> insert(DefT table, Map<String, dynamic> value) =>
      _database.insert(table.name, value);

  @override
  Future<List<Map<String, dynamic>>> select(DefT table) =>
      _database.query(table.name);

  @override
  Future<Map<String, dynamic>> selectById(DefT table, id) async =>
      (await _database.query(
        table.name,
        where: _buildWhereId(table),
        whereArgs: [id],
      ))
          .first;

  @override
  Future<int> updateById(DefT table, Map<String, dynamic> value, id) =>
      _database.update(
        table.name,
        value,
        where: _buildWhereId(table),
        whereArgs: [id],
      );

  @override
  Future<int> deleteById(DefT table, id) => _database.delete(
        table.name,
        where: _buildWhereId(table),
        whereArgs: [id],
      );

  @override
  Future<int> deleteAll(DefT table) => _database.delete(table.name);

  _buildWhereId(DefT table) =>
      '${table.fields.whereType<DefPK>().first.name} = ?';

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
    _pathFuture = databaseDirectoryPath.then((value) => path.join(value, name));
  }

  _onCreate(sqflite.Database db, int version, List<TableDefinition> tables) {
    for (var table in tables) {
      db.execute(table.buildCreateSql());
    }
  }
}
