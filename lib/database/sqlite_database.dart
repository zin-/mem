import 'dart:async';
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
    if (kIsWeb) throw DatabaseException('Unsupported platform. Platform: Web');
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
        () => SqliteTable(tableDefinition, _database, this),
      );
    }

    isOpen = true;
    return this;
  }

  @override
  Future<bool> close() async => await onOpened(
        () async {
          await _database.close();
          isOpen = false;
          return true;
        },
        () async {
          print(
            'Close failed.'
            ' Database does not exist.'
            ' databasePath: ${await _pathFuture}',
          );
          return false;
        },
      );

  @override
  Future<bool> delete() async => await onOpened(
        () async {
          await _factory.deleteDatabase(await _pathFuture);
          isOpen = false;
          return true;
        },
        () async {
          print(
            'Delete failed.'
            ' Database does not exist.'
            ' databasePath: ${await _pathFuture}',
          );
          return false;
        },
      );

  void _initialize() {
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

  @override
  Future<T> checkExists<T>(
    FutureOr<T> Function() onTrue,
    FutureOr<T> Function() onFalse,
  ) async {
    if (await _factory.databaseExists(await _pathFuture)) {
      return await onTrue();
    } else {
      return await onFalse();
    }
  }
}

class SqliteTable extends Table {
  final SqliteDatabase _database2;
  final sqflite.Database _database;

  SqliteTable(super.definition, this._database, this._database2);

  @override
  Future<int> insert(Map<String, dynamic> value) async =>
      await _database2.onOpened(
        () async => await _database.insert(definition.name, convertTo(value)),
        () => throw DatabaseDoesNotExistException(_database2.definition.name),
      );

  @override
  Future<List<Map<String, dynamic>>> select() async =>
      await _database2.onOpened(
        () async => (await _database.query(definition.name))
            .map((e) => convertFrom(e))
            .toList(),
        () => throw DatabaseDoesNotExistException(_database2.definition.name),
      );

  @override
  Future<Map<String, dynamic>> selectByPk(pk) async {
    return await _database2.onOpened(
      () async {
        final selectedByPk = await _database.query(
          definition.name,
          where: _buildWhereId(),
          whereArgs: [pk],
        );

        if (selectedByPk.length == 1) {
          return convertFrom(selectedByPk.first);
        } else {
          throw NotFoundException(
            definition.name,
            _buildWhereId().replaceFirst('?', pk.toString()),
          );
        }
      },
      () => throw DatabaseDoesNotExistException(_database2.definition.name),
    );
  }

  @override
  Future<int> updateByPk(pk, Map<String, dynamic> value) async =>
      await _database2.onOpened(
        () async => await _database.update(
          definition.name,
          convertTo(value),
          where: _buildWhereId(),
          whereArgs: [pk],
        ),
        () => throw DatabaseDoesNotExistException(_database2.definition.name),
      );

  @override
  Future<int> deleteByPk(pk) async => await _database2.onOpened(
        () async => await _database.delete(
          definition.name,
          where: _buildWhereId(),
          whereArgs: [pk],
        ),
        () => throw DatabaseDoesNotExistException(_database2.definition.name),
      );

  @override
  Future<int> delete() async => await _database2.onOpened(
        () async => await _database.delete(definition.name),
        () => throw DatabaseDoesNotExistException(_database2.definition.name),
      );

  String _buildWhereId() =>
      '${definition.columns.whereType<DefPK>().first.name} = ?';
}
