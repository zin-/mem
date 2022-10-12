import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

class SqliteDatabase extends Database {
  bool foreignKeyIsEnabled = false;

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
  Future<SqliteDatabase> open() => v(
        {},
        () async {
          _database = await _factory.openDatabase(
            await _pathFuture,
            options: sqflite.OpenDatabaseOptions(
              version: definition.version,
              onCreate: _onCreate,
              onConfigure: _onConfigure,
              onUpgrade: _onUpgrade,
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

  _onCreate(db, version) => v(
        {'db': db, 'version': version},
        () async {
          trace('Create Database. $definition');
          for (var tableDefinition in definition.tableDefinitions) {
            trace('Create table. $tableDefinition');
            await db.execute(tableDefinition.buildCreateTableSql());
          }
        },
      );

  _onConfigure(db) => v(
        {'db': db},
        () async {
          for (var tableDefinition in definition.tableDefinitions) {
            if (!foreignKeyIsEnabled &&
                tableDefinition.columns.whereType<DefFK>().isNotEmpty) {
              verbose('Enable foreign key');
              await db.execute('PRAGMA foreign_keys=true');
              foreignKeyIsEnabled = true;
            }
          }
        },
      );

  _onUpgrade(sqflite.Database db, int oldVersion, int newVersion) => v(
        {
          'db': db,
          'oldVersion': oldVersion,
          'newVersion': newVersion,
        },
        () async {
          const tmpPrefix = 'tmp_';

          trace('Upgrade Database. $definition from version: $oldVersion');

          for (var tableDefinition in definition.tableDefinitions) {
            final master = await db.query(
              'sqlite_master',
              where: 'type = ? AND name = ?',
              whereArgs: ['table', tableDefinition.name],
            );
            if (master.isEmpty) {
              trace('Create table. $tableDefinition');
              await db.execute(tableDefinition.buildCreateTableSql());
            } else {
              if (tableDefinition.buildCreateTableSql() !=
                  master.single['sql']) {
                trace('Alter table. $tableDefinition');

                final rows = await db.query(tableDefinition.name);

                final tmpTableName = '$tmpPrefix${tableDefinition.name}';
                final batch = db.batch();
                batch.execute(
                  'ALTER TABLE ${tableDefinition.name} RENAME TO $tmpTableName',
                );
                batch.execute(tableDefinition.buildCreateTableSql());
                for (var row in rows) {
                  batch.insert(tableDefinition.name, row);
                }
                await batch.commit();
                // FIXME 以下を実行することで、NULLで返却されるようになる
                // SQLiteのバグに見える
                // 一度アクセスしないとDEFAULT NULLの値が設定されない
                db.query(tableDefinition.name);
              }
            }
          }

          final tmpTableMasters = await db.query(
            'sqlite_master',
            where: 'type = ? AND name like ?',
            whereArgs: ['table', '$tmpPrefix%'],
          );
          final batch = db.batch();
          for (var tmpTableMaster in tmpTableMasters.reversed) {
            batch.execute('DROP TABLE ${tmpTableMaster['name']}');
          }
          await batch.commit();
        },
      );
}

class SqliteTable extends Table {
  final SqliteDatabase _database;

  SqliteTable(super.definition, this._database);

  @override
  Future<int> insert(Map<String, dynamic> valueMap) => v(
        {'valueMap': valueMap},
        () async => await _database.onOpened(
          () async => await _database._database
              .insert(definition.name, convertTo(valueMap)),
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
