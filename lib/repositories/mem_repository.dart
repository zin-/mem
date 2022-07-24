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
