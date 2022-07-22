import 'dart:convert';

import 'package:idb_shim/idb.dart' as idb_shim;
import 'package:idb_shim/idb_browser.dart' as idb_browser;

import 'package:mem/database/database.dart';

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
