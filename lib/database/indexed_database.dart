// coverage:ignore-file
// WEBでテストするときにカバレッジを取得する方法がないため
import 'dart:async';
import 'dart:convert';

import 'package:idb_shim/idb.dart' as idb_shim;
import 'package:idb_shim/idb_browser.dart' as idb_browser;
import 'package:mem/database/database.dart';
import 'package:mem/database/i/types.dart';
import 'package:mem/logger/i/api.dart';

class IndexedDatabase extends Database {
  IndexedDatabase(super.definition) {
    if (definition.tableDefinitions.isEmpty) {
      // FIXME DBの存在チェックのため最低1つのストアが必要な仕様になっている
      throw DatabaseException('Requires at least 1 table.');
    }
  }

  final idb_shim.IdbFactory _factory = idb_browser.idbFactoryBrowser;
  late final idb_shim.Database _database;

  @override
  Future<IndexedDatabase> open() => v(
        {},
        () async {
          _database = await _factory.open(
            definition.name,
            version: definition.version,
            onUpgradeNeeded: (event) {
              trace('Create Database. $definition');
              for (var tableDefinition in definition.tableDefinitions) {
                trace('Create object. $tableDefinition');
                event.database.createObjectStore(
                  tableDefinition.name,
                  autoIncrement: tableDefinition.columns
                      .whereType<DefPK>()
                      .first
                      .autoincrement,
                );
              }
            },
          );

          for (var tableDefinition in definition.tableDefinitions) {
            tables.putIfAbsent(
              tableDefinition.name,
              () => ObjectStore(tableDefinition, this),
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
          () {
            _database.close();
            isOpen = false;
            return true;
          },
          () {
            warn(
              'Close failed.'
              ' Database does not exist.'
              ' databaseName: ${definition.name}',
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
            await close();
            await _factory.deleteDatabase(
              definition.name,
              onBlocked: (event) {
                warn('onBlocked :: event: $event');
              },
            );
            return true;
          },
          () async {
            warn(
              'Delete failed.'
              ' Database does not exist.'
              ' databaseName: ${definition.name}',
            );
            return false;
          },
        ),
      );

  @override
  Future<T> checkExists<T>(
    FutureOr<T> Function() onTrue,
    FutureOr<T> Function() onFalse,
  ) async {
    try {
      // FIXME トランザクションを開始するために、最低1つのストアが必要な仕様になっている
      // idb_shimにデータベースが存在しているかを確認するAPIがないため
      await _database
          .transaction(tables.keys.first, idb_shim.idbModeReadOnly)
          .completed;
      return await onTrue();
    } catch (e) {
      warn(e);
      if (e is DatabaseException) {
        rethrow;
      }
      return await onFalse();
    }
  }
}

class ObjectStore extends Table {
  final IndexedDatabase _database;

  ObjectStore(super.definition, this._database);

  late final _pkColumn = definition.columns.whereType<DefPK>().first;

  @override
  Future<int> insert(Map<String, dynamic> valueMap) => v(
        {'valueMap': valueMap},
        () async => await _database.onOpened(
          () async {
            final defFks = definition.columns.whereType<DefFK>();

            final txn = _database._database.transaction(
                defFks.isEmpty
                    ? definition.name
                    : [
                        definition.name,
                        ...defFks.map((e) => e.parentTableDefinition.name)
                      ],
                idb_shim.idbModeReadWrite);

            for (var defFk in defFks) {
              final parentStoreName = defFk.parentTableDefinition.name;
              final parentStore = txn.objectStore(parentStoreName);
              final parentKey = valueMap[defFk.name];
              final parentExists = await parentStore.count(parentKey) > 0;
              if (!parentExists) {
                throw ParentNotFoundException(
                  parentStoreName,
                  'id = $parentKey',
                );
              }
            }

            final store = txn.objectStore(definition.name);
            final generatedPk = await store.add(convertTo(valueMap));
            // TODO 更新数が1かを確認した方が良いかも
            await store.put(
              convertTo(
                valueMap..putIfAbsent(_pkColumn.name, () => generatedPk),
              ),
              generatedPk,
            );

            await txn.completed;

            return int.parse(generatedPk.toString());
          },
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  @override
  Future<List<Map<String, dynamic>>> select({
    String? whereString,
    List<Object?>? whereArgs,
  }) =>
      v(
        {'where': whereString, 'whereArgs': whereArgs},
        () async => await _database.onOpened(
          () async {
            // TODO implements where
            final txn = _database._database
                .transaction(definition.name, idb_shim.idbModeReadOnly);

            final objects = await txn.objectStore(definition.name).getAll();

            await txn.completed;

            return objects
                .map((object) => convertFrom(_convertIntoMap(object)))
                .toList();
          },
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  @override
  Future<Map<String, dynamic>> selectByPk(pk) => v(
        {'pk': pk},
        () async => await _database.onOpened(
          () async {
            final txn = _database._database
                .transaction(definition.name, idb_shim.idbModeReadOnly);

            final object = await txn.objectStore(definition.name).getObject(pk);

            await txn.completed;

            if (object == null) {
              throw NotFoundException(
                definition.name,
                'id = $pk',
              );
            }

            return convertFrom(_convertIntoMap(object));
          },
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  @override
  Future<int> updateByPk(pk, Map<String, dynamic> value) => v(
        {'pk': pk, 'value': value},
        () async => await _database.onOpened(
          () async {
            final txn = _database._database
                .transaction(definition.name, idb_shim.idbModeReadWrite);
            final store = txn.objectStore(definition.name);

            final savedObject = await store.getObject(pk);
            if (savedObject == null) {
              await txn.completed;
              throw NotFoundException(
                definition.name,
                'id = $pk',
              );
            }
            final saved = _convertIntoMap(savedObject);
            value.forEach((key, value) {
              saved[key] = value;
            });
            final putCount = await txn
                .objectStore(definition.name)
                .put(convertTo(saved), pk);
            await txn.completed;

            return int.parse(putCount.toString());
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
          () async {
            final txn = _database._database
                .transaction(definition.name, idb_shim.idbModeReadWrite);

            await txn.objectStore(definition.name).delete(pk);

            await txn.completed;

            return 1;
          },
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  @override
  Future<int> delete() => v(
        {},
        () async => await _database.onOpened(
          () async {
            final txn = _database._database
                .transaction(definition.name, idb_shim.idbModeReadWrite);
            final store = txn.objectStore(definition.name);

            final count = await store.count();
            await store.clear();

            await txn.completed;

            return count;
          },
          () => throw DatabaseDoesNotExistException(_database.definition.name),
        ),
      );

  Map<String, dynamic> _convertIntoMap(Object? object) {
    final json = jsonDecode(jsonEncode(object));
    return Map.fromEntries(
        definition.columns.map((f) => MapEntry(f.name, json[f.name])));
  }
}
