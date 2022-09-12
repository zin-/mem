import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/repository.dart';

const memIdColumnName = 'mems_id';
const memDetailTypeColumnName = 'type';
const memDetailValueColumnName = 'value';

final memItemTableDefinition = DefT(
  'mem_items',
  [
    DefPK(idColumnName, TypeC.integer, autoincrement: true),
    DefC(memDetailTypeColumnName, TypeC.text),
    DefC(memDetailValueColumnName, TypeC.text),
    ...defaultColumnDefinitions,
    DefFK(memTableDefinition),
  ],
);

class MemItemEntity extends DatabaseTableEntity {
  int? memId;
  MemItemType type;
  dynamic value;

  MemItemEntity({
    required this.memId,
    required this.type,
    this.value,
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) : super(
          id: id,
          createdAt: createdAt ?? DateTime.now(),
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  MemItemEntity.fromMap(super.valueMap)
      : memId = valueMap[memIdColumnName],
        type = valueMap[memDetailTypeColumnName],
        value = valueMap[memDetailValueColumnName],
        super.fromMap();

  @override
  Map<String, dynamic> toMap() => {
        memIdColumnName: memId,
        memDetailTypeColumnName: type,
        memDetailValueColumnName: value,
      }..addAll(super.toMap());
}

class MemItemRepository extends DatabaseTableRepository<MemItemEntity> {
  Future<List<MemItemEntity>> shipByMemId(int memId) => v(
        {'memId': memId},
        () => ship(
          archived: false,
          where: [memIdColumnName],
          whereArgs: [memId],
        ),
      );

  Future<List<MemItemEntity>> archiveByMemId(int memId) => v(
        {'memId': memId},
        () async {
          return await Future.wait((await ship(
            where: [memIdColumnName],
            whereArgs: [memId],
          ))
              .map((archiving) => archive(archiving)));
        },
      );

  Future<List<MemItemEntity>> unarchiveByMemId(int memId) => v(
        {'memId': memId},
        () async {
          return await Future.wait((await ship(
            where: [memIdColumnName],
            whereArgs: [memId],
          ))
              .map((unarchiving) => unarchive(unarchiving)));
        },
      );

  Future<List<bool>> discardByMemId(int memId) => v(
        {'memId': memId},
        () async {
          return await Future.wait((await ship(
            where: [memIdColumnName],
            whereArgs: [memId],
          ))
              .map((discarding) => discardById(discarding.id)));
        },
      );

  @override
  MemItemEntity fromMap(Map<String, dynamic> valueMap) =>
      MemItemEntity.fromMap(valueMap);

  static MemItemRepository? _instance;

  MemItemRepository._(super.table);

  factory MemItemRepository() {
    var tmp = _instance;
    if (tmp == null) {
      throw Exception('Call initialize'); // coverage:ignore-line
    } else {
      return tmp;
    }
  }

  factory MemItemRepository.initialize(Table table) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = MemItemRepository._(table);
      _instance = tmp;
    }
    return tmp;
  }

  factory MemItemRepository.withMock(MemItemRepository mock) {
    _instance = mock;
    return mock;
  }

  static clear() => _instance = null;
}

const memMemoName = 'memo';

enum MemItemType {
  memo,
}
