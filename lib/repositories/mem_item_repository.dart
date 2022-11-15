import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger/api.dart';
import 'package:mem/domain/mem.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';

const memIdColumnName = 'mems_id';
const memItemTypeColumnName = 'type';
const memItemValueColumnName = 'value';

final memItemTableDefinition = DefT(
  'mem_items',
  [
    DefPK(idColumnName, TypeC.integer, autoincrement: true),
    DefC(memItemTypeColumnName, TypeC.text),
    DefC(memItemValueColumnName, TypeC.text),
    ...defaultColumnDefinitions,
    DefFK(memTableDefinition),
  ],
);

class MemItemEntity extends DatabaseTupleEntity {
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
          createdAt: createdAt,
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  MemItemEntity.fromMap(super.valueMap)
      : memId = valueMap[memIdColumnName],
        type = MemItemType.values.firstWhere(
            (element) => element.name == valueMap[memItemTypeColumnName]),
        value = valueMap[memItemValueColumnName],
        super.fromMap();

  @override
  Map<String, dynamic> toMap() => {
        memIdColumnName: memId,
        memItemTypeColumnName: type.name,
        memItemValueColumnName: value,
      }..addAll(super.toMap());
}

class MemItemRepository extends DatabaseTupleRepository<MemItemEntity> {
  Future<List<MemItemEntity>> shipByMemId(int memId) => v(
        {'memId': memId},
        () => ship(
          whereMap: {memIdColumnName: memId},
        ),
      );

  Future<List<MemItemEntity>> archiveByMemId(int memId) => v(
        {'memId': memId},
        () async {
          return await Future.wait(
              (await shipByMemId(memId)).map((target) => archive(target)));
        },
      );

  Future<List<MemItemEntity>> unarchiveByMemId(int memId) => v(
        {'memId': memId},
        () async {
          return await Future.wait(
              (await shipByMemId(memId)).map((target) => unarchive(target)));
        },
      );

  Future<List<bool>> discardByMemId(int memId) => v(
        {'memId': memId},
        () async {
          return await Future.wait((await shipByMemId(memId))
              .map((discarding) => discardById(discarding.id)));
        },
      );

  @override
  MemItemEntity fromMap(Map<String, dynamic> valueMap) =>
      MemItemEntity.fromMap(valueMap);

  static MemItemRepository? _instance;

  MemItemRepository._(super.table);

  factory MemItemRepository([Table? memItemTable]) {
    var tmp = _instance;
    if (tmp == null) {
      if (memItemTable == null) {
        throw Exception('Call initialize'); // coverage:ignore-line
      }
      tmp = MemItemRepository._(memItemTable);
      _instance = tmp;
    }
    return tmp;
  }

  static void reset(MemItemRepository? memRepository) {
    _instance = memRepository;
  }
}
