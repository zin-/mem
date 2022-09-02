import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mem/logger.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';

class SqliteDatabase extends Database {
  SqliteDatabase(super.definition) {
    if (kIsWeb) {
      throw DatabaseException(
          'Unsupported platform. Platform: Web'); // coverage:ignore-line
      // WEBでテストするときにカバレッジを取得する方法がないため
    }
    _initialize();
  }

  late final sqflite.DatabaseFactory _factory;
  late final Future<String> _pathFuture;
  late final sqflite.Database _database;

  @override
  Future<Database> open() => v(
        {},
        () async {
          _database = await _factory.openDatabase(
            await _pathFuture,
            options: sqflite.OpenDatabaseOptions(
              version: definition.version,
              onCreate: (db, version) async {
                trace('Create Database. $definition');
                for (var tableDefinition in definition.tableDefinitions) {
                  trace('Create table. $tableDefinition');
                  await db.execute(tableDefinition.buildCreateTableSql());
                }
              },
            ),
          );

          for (var tableDefinition in definition.tableDefinitions) {
            tables.putIfAbsent(
              tableDefinition.name,
              () => SqliteTable(tableDefinition, this),
            );
          }

          isOpen = true;
          return this;
        },
      );

  @override
  Future<bool> close() => v(
        {},
        () async => await onOpened(
          () async {
            await _database.close();
            isOpen = false;
            return true;
          },
          () async {
            warn(
              'Close failed.'
              ' Database does not exist.'
              ' databasePath: ${await _pathFuture}',
            );
            return false;
          },
        ),
      );

  @override
  Future<bool> delete() => v(
        {},
        () async => await checkExists(
          () async {
            await _factory.deleteDatabase(await _pathFuture);
            isOpen = false;
            return true;
          },
          () async {
            warn(
              'Delete failed.'
              ' Database does not exist.'
              ' databasePath: ${await _pathFuture}',
            );
            return false;
          },
        ),
      );

  void _initialize() => v(
        {},
        () {
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
            // coverage:ignore-start
            throw DatabaseException(
                'Unsupported platform. platform: ${Platform.operatingSystem}');
            // coverage:ignore-end
            // WEBでテストするときにカバレッジを取得する方法がないため
          }
          _pathFuture = databaseDirectoryPath
              .then((value) => path.join(value, definition.name));
        },
      );

  @override
  Future<T> checkExists<T>(
    FutureOr<T> Function() onTrue,
    FutureOr<T> Function() onFalse,
  ) async =>
      (await _factory.databaseExists(await _pathFuture))
          ? await onTrue()
          : await onFalse();
}

class SqliteTable extends Table {
  final SqliteDatabase _database;

  SqliteTable(super.definition, this._database);

  @override
  Future<int> insert(Map<String, dynamic> value) => v(
        {'value': value},
        () async => await _database.onOpened(
          () async => await _database._database
              .insert(definition.name, convertTo(value)),
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  @override
  Future<List<Map<String, dynamic>>> select({
    String? where,
    List<Object?>? whereArgs,
  }) =>
      v(
        {'where': where, 'whereArgs': whereArgs},
        () async => await _database.onOpened(
          () async => (await _database._database.query(
            definition.name,
            where: where,
            whereArgs: whereArgs,
          ))
              .map((e) => convertFrom(e))
              .toList(),
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  @override
  Future<Map<String, dynamic>> selectByPk(pk) => v(
        {'pk': pk},
        () async => await _database.onOpened(
          () async {
            final selectedByPk = await _database._database.query(
              definition.name,
              where: _buildWhereId(),
              whereArgs: [pk],
            );

            if (selectedByPk.isEmpty) {
              throw NotFoundException(
                definition.name,
                _buildWhereId().replaceFirst('?', pk.toString()),
              );
            } else {
              return convertFrom(selectedByPk.first);
            }
          },
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  @override
  Future<int> updateByPk(pk, Map<String, dynamic> value) => v(
        {'pk': pk, 'value': value},
        () => _database.onOpened(
          () async {
            final updateCount = await _database._database.update(
              definition.name,
              convertTo(value),
              where: _buildWhereId(),
              whereArgs: [pk],
            );

            if (updateCount == 0) {
              throw NotFoundException(
                definition.name,
                _buildWhereId().replaceFirst('?', pk.toString()),
              );
            } else {
              return updateCount;
            }
          },
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  @override
  Future<int> patchByPk(pk, Map<String, dynamic> value) {
    // TODO: implement patchByPk
    throw UnimplementedError();
  }

  @override
  Future<int> deleteByPk(pk) => v(
        {'pk': pk},
        () async => await _database.onOpened(
          () async => await _database._database.delete(
            definition.name,
            where: _buildWhereId(),
            whereArgs: [pk],
          ),
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  @override
  Future<int> delete() => v(
        {},
        () async => await _database.onOpened(
          () async => await _database._database.delete(definition.name),
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  String _buildWhereId() =>
      '${definition.columns.whereType<DefPK>().first.name} = ?';
}
