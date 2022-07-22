import 'package:mem/database/database.dart';
import 'package:mem/mem.dart';

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
