import 'dart:convert';

import 'package:idb_shim/idb.dart' as idb_shim;
import 'package:idb_shim/idb_browser.dart' as idb_browser;

import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';

class IndexedDatabaseV2 extends DatabaseV2 {
  IndexedDatabaseV2(super.definition);

  final idb_shim.IdbFactory _factory = idb_browser.idbFactoryBrowser;
  late final idb_shim.Database _database;

  @override
  Future<DatabaseV2> open() async {
    _database = await _factory.open(
      definition.name,
      version: definition.version,
      onUpgradeNeeded: (event) {
        for (var tableDefinition in definition.tableDefinitions) {
          event.database.createObjectStore(
            tableDefinition.name,
            autoIncrement: tableDefinition.columns
                .whereType<DefPKV2>()
                .first
                .autoincrement,
          );
        }
      },
    );

    for (var tableDefinition in definition.tableDefinitions) {
      tables.putIfAbsent(
        tableDefinition.name,
        () => ObjectStore(tableDefinition, _database),
      );
    }

    return this;
  }

  @override
  close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  Future<void> delete() async {
    _database.close();
    await _factory.deleteDatabase(definition.name);
  }
}

class ObjectStore extends TableV2 {
  final idb_shim.Database _database;

  ObjectStore(super.definition, this._database);

  late final _pkColumn = definition.columns.whereType<DefPKV2>().first;

  @override
  Future<int> insert(Map<String, dynamic> value) async {
    final txn =
        _database.transaction(definition.name, idb_shim.idbModeReadWrite);

    final store = txn.objectStore(definition.name);
    final generatedPk = await store.add(convertTo(value));
    // TODO 更新数が1かを確認した方が良いかも
    await store.put(
      convertTo(value..putIfAbsent(_pkColumn.name, () => generatedPk)),
      generatedPk,
    );

    await txn.completed;

    return int.parse(generatedPk.toString());
  }

  @override
  Future<List<Map<String, dynamic>>> select() async {
    final txn =
        _database.transaction(definition.name, idb_shim.idbModeReadOnly);

    final objects = await txn.objectStore(definition.name).getAll();

    await txn.completed;

    return objects
        .map((object) => convertFrom(_convertIntoMap(object)))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> selectByPk(pk) async {
    final txn =
        _database.transaction(definition.name, idb_shim.idbModeReadOnly);

    final object = await txn.objectStore(definition.name).getObject(pk);

    await txn.completed;

    return convertFrom(_convertIntoMap(object));
  }

  @override
  Future<int> updateByPk(pk, Map<String, dynamic> value) async {
    final txn =
        _database.transaction(definition.name, idb_shim.idbModeReadWrite);
    final store = txn.objectStore(definition.name);

    final saved = _convertIntoMap(await store.getObject(pk));
    value.forEach((key, value) {
      saved[key] = value;
    });
    final putCount =
        await txn.objectStore(definition.name).put(convertTo(saved), pk);
    await txn.completed;

    return int.parse(putCount.toString());
  }

  @override
  Future<int> deleteByPk(pk) async {
    final txn =
        _database.transaction(definition.name, idb_shim.idbModeReadWrite);

    await txn.objectStore(definition.name).delete(pk);

    await txn.completed;

    return 1;
  }

  @override
  Future<int> delete() async {
    final txn =
        _database.transaction(definition.name, idb_shim.idbModeReadWrite);
    final store = txn.objectStore(definition.name);

    final count = await store.count();
    await store.clear();

    await txn.completed;

    return count;
  }

  Map<String, dynamic> _convertIntoMap(Object? object) {
    final json = jsonDecode(jsonEncode(object));
    return Map.fromEntries(
        definition.columns.map((f) => MapEntry(f.name, json[f.name])));
  }
}

class IndexedDatabase extends Database {
  IndexedDatabase(super.name, super.version, super.tables);

  final idb_shim.IdbFactory _factory = idb_browser.idbFactoryBrowser;
  late final idb_shim.Database _database;

  @override
  Future<Database> open() async {
    _database = await _factory.open(
      name,
      version: version,
      onUpgradeNeeded: (event) {
        for (var table in tables) {
          event.database.createObjectStore(table.name, autoIncrement: true);
        }
      },
    );

    return this;
  }

  @override
  Future<bool> delete() async {
    if (_factory.persistent) {
      await _factory.deleteDatabase(name);
      return true;
    } else {
      print(
        'Delete failed.'
        ' Database does not exist.'
        ' databaseName: $name',
      );
      return false;
    }
  }

  @override
  Future<int> insert(DefT table, Map<String, dynamic> value) async {
    final txn = _database.transaction(table.name, idb_shim.idbModeReadWrite);
    final store = txn.objectStore(table.name);
    final added = await store.add(value);
    await store.put(value..putIfAbsent('id', () => added), added);
    return await txn.completed.then((value) => int.parse(added.toString()));
  }

  @override
  Future<List<Map<String, dynamic>>> select(DefT table) async {
    final txn = _database.transaction(table.name, idb_shim.idbModeReadOnly);
    final objects = await txn.objectStore(table.name).getAll();
    return await txn.completed.then((value) =>
        objects.map((object) => _convertIntoMap(object, table)).toList());
  }

  @override
  Future<Map<String, dynamic>> selectById(DefT table, id) async {
    final txn = _database.transaction(table.name, idb_shim.idbModeReadOnly);
    final object = await txn.objectStore(table.name).getObject(id);
    return await txn.completed.then((value) => _convertIntoMap(object, table));
  }

  @override
  Future<int> updateById(DefT table, Map<String, dynamic> value, id) async {
    final txn = _database.transaction(table.name, idb_shim.idbModeReadWrite);
    value[table.fields.whereType<PrimaryKeyDefinition>().first.name] = id;
    final put = await txn.objectStore(table.name).put(value, id);
    return await txn.completed.then((value) => int.parse(put.toString()));
  }

  @override
  Future<int> deleteById(DefT table, id) async {
    final txn = _database.transaction(table.name, idb_shim.idbModeReadWrite);
    await txn.objectStore(table.name).delete(id);
    return await txn.completed.then((value) => 1);
  }

  @override
  Future<int> deleteAll(DefT table) async {
    final txn = _database.transaction(table.name, idb_shim.idbModeReadWrite);
    final store = txn.objectStore(table.name);
    final count = await store.count();
    await store.clear();
    return await txn.completed.then((value) => count);
  }

  Map<String, dynamic> _convertIntoMap(Object? object, DefT table) {
    final json = jsonDecode(jsonEncode(object));
    return Map.fromEntries(
        table.fields.map((f) => MapEntry(f.name, json[f.name])));
  }
}
