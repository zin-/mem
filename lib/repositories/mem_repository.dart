import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/mem.dart';

class MemRepositoryV2 {
  final TableV2 _memTable;

  Future<Mem> receive(Map<String, dynamic> value) async {
    final createdAt = DateTime.now();
    int id = await _memTable
        .insert(value..putIfAbsent('createdAt', () => createdAt));
    return Mem(id: id, name: value['name'], createdAt: createdAt);
  }

  Future<List<Mem>> selectAll() async =>
      (await _memTable.select()).map((e) => Mem.fromMap(e)).toList();

  Future<Mem> selectById(dynamic id) async =>
      Mem.fromMap(await _memTable.selectByPk(id));

  Future<Mem> update(Mem mem) async {
    final value = mem.toMap();
    value['updatedAt'] = DateTime.now();
    // TODO 更新数が1かを確認した方が良いかも
    await _memTable.updateByPk(mem.id, value);
    return Mem.fromMap(value);
  }

  // TODO implement
  // patchWhereId(dynamic id, Map<String, dynamic> value) {}
  // archiveWhereId(dynamic id) async {}

  Future<bool> removeById(dynamic id) async {
    int deletedCount = await _memTable.deleteByPk(id);
    if (deletedCount == 1) {
      return true;
    } else {
      return false;
    }
  }

  Future<int> removeAll() async => _memTable.delete();

  MemRepositoryV2._(this._memTable);

  static MemRepositoryV2? _instance;

  factory MemRepositoryV2(TableV2 memTable) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = MemRepositoryV2._(memTable);
      _instance = tmp;
    }
    return tmp;
  }
}

final memTableV2 = DefTV2(
  'mems',
  [
    DefPKV2('id', TypeCV2.integer, autoincrement: true),
    DefC('name', TypeCV2.text),
    DefC('createdAt', TypeCV2.datetime),
    DefC('updatedAt', TypeCV2.datetime, notNull: false),
    DefC('archivedAt', TypeCV2.datetime, notNull: false),
  ],
);

class MemRepository {
  final Database _database;

  Future<Mem> receive(Map<String, dynamic> value) async {
    final createdAt = DateTime.now();
    int id = await _database.insert(memTable,
        _convertForDatabase(value..putIfAbsent('createdAt', () => createdAt)));
    return Mem(id: id, name: value['name'], createdAt: createdAt);
  }

  Future<int> removeAll() async => _database.deleteAll(memTable);

  Future<Mem> selectById(int id) async {
    final map = await _database.selectById(memTable, id);
    final converted = _convertFromDatabase(map);
    return Mem.fromMap(converted);
  }

  Future<List<Mem>> select() async =>
      (await _database.select(memTable)).map((e) => Mem.fromMap(e)).toList();

  Future<Mem> update(Mem mem) async {
    final value = mem.toMap();
    final updatedAt = DateTime.now();
    value['updatedAt'] = updatedAt;
    final map = _convertForDatabase(value);
    await _database.updateById(memTable, map, mem.id);
    return Mem.fromMap(map);
  }

  // TODO implement
  // patchWhereId(dynamic id, Map<String, dynamic> value) {}
  // archiveWhereId(dynamic id) async {}

  Future<bool> removeById(dynamic id) async {
    int deletedCount = await _database.deleteById(memTable, id);
    if (deletedCount == 1) {
      return true;
    } else {
      return false;
    }
  }

  Map<String, dynamic> _convertForDatabase(Map<String, dynamic> value) {
    return value.map((key, value) {
      return MapEntry(
        key,
        memTable.fields
            .where((f) => f.name == key)
            .first
            .convertForDatabase(value),
      );
    });
  }

  Map<String, dynamic> _convertFromDatabase(Map<String, dynamic> value) {
    return value.map((key, value) {
      return MapEntry(
        key,
        memTable.fields
            .where((f) => f.name == key)
            .first
            .convertFromDatabase(value),
      );
    });
  }

  MemRepository._(this._database);

  static MemRepository? _instance;

  factory MemRepository(Database database) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = MemRepository._(database);
      _instance = tmp;
    }
    return tmp;
  }
}

final memTable = DefT(
  'mems',
  [
    DefPK('id', FieldType.integer, autoincrement: true),
    DefF('name', FieldType.text),
    DefF('createdAt', FieldType.datetime),
    DefF('updatedAt', FieldType.datetime, notNull: false),
    DefF('archivedAt', FieldType.datetime, notNull: false),
  ],
);
