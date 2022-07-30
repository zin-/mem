import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem.dart';

class MemRepository {
  final Table _memTable;

  Future<Mem> receive(Map<String, dynamic> value) => v(
        {'value': value},
        () async {
          final createdAt = DateTime.now();
          int id = await _memTable
              .insert(value..putIfAbsent('createdAt', () => createdAt));
          return Mem(id: id, name: value['name'], createdAt: createdAt);
        },
      );

  Future<List<Mem>> shipAll() => v(
        {},
        () async =>
            (await _memTable.select()).map((e) => Mem.fromMap(e)).toList(),
      );

  Future<Mem> shipWhereIdIs(dynamic id) => v(
        {'id': id},
        () async => Mem.fromMap(await _memTable.selectByPk(id)),
      );

  Future<Mem> update(Mem mem) => v(
        {'mem': mem},
        () async {
          final value = mem.toMap();
          value['updatedAt'] = DateTime.now();
          // TODO 更新数が1かを確認した方が良いかも
          await _memTable.updateByPk(mem.id, value);
          return Mem.fromMap(value);
        },
      );

  // TODO implement
  // patchWhereId(dynamic id, Map<String, dynamic> value) {}
  // archiveWhereId(dynamic id) async {}

  Future<bool> discardWhereIdIs(dynamic id) => v(
        {'id': id},
        () async {
          int deletedCount = await _memTable.deleteByPk(id);
          if (deletedCount == 1) {
            return true;
          } else {
            return false;
          }
        },
      );

  Future<int> discardAll() => v(
        {},
        () async => _memTable.delete(),
      );

  MemRepository._(this._memTable);

  static MemRepository? _instance;

  factory MemRepository() {
    var tmp = _instance;
    if (tmp == null) {
      throw RepositoryException('Call initialize'); // coverage:ignore-line
    } else {
      return tmp;
    }
  }

  factory MemRepository.initialize(Table memTable) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = MemRepository._(memTable);
      _instance = tmp;
    }
    return tmp;
  }

  factory MemRepository.withMock(MemRepository mock) {
    _instance = mock;
    return mock;
  }

  static clear() => _instance = null;
}

const memTableName = 'mems';
final memTable = DefT(
  memTableName,
  [
    DefPK('id', TypeC.integer, autoincrement: true),
    DefC('name', TypeC.text),
    DefC('createdAt', TypeC.datetime),
    DefC('updatedAt', TypeC.datetime, notNull: false),
    DefC('archivedAt', TypeC.datetime, notNull: false),
  ],
);

class RepositoryException implements Exception {
  final String message;

  RepositoryException(this.message);

  @override
  String toString() => message;
}
