import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/repository.dart';

const memIdColumnName = 'mems_id';
const memDetailTypeColumnName = 'type';
const memDetailValueColumnName = 'value';

final memDetailTableDefinition = DefT(
  'mem_details',
  [
    DefPK(idColumnName, TypeC.integer, autoincrement: true),
    DefC(memDetailTypeColumnName, TypeC.text),
    DefC(memDetailValueColumnName, TypeC.text),
    DefFK(memTableDefinition),
    ...defaultColumnDefinitions,
  ],
);

class MemDetailEntity extends DatabaseTableEntity {
  int memId;
  MemDetailType type;
  dynamic value;

  MemDetailEntity({
    required this.memId,
    required this.type,
    this.value,
    required int id,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  MemDetailEntity.fromMap(super.valueMap)
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

class MemDetailRepository extends DatabaseTableRepository<MemDetailEntity> {
  @override
  MemDetailEntity fromMap(Map<String, dynamic> valueMap) =>
      MemDetailEntity.fromMap(valueMap);

  static MemDetailRepository? _instance;

  MemDetailRepository._(super.table);

  factory MemDetailRepository() {
    var tmp = _instance;
    if (tmp == null) {
      throw Exception('Call initialize'); // coverage:ignore-line
    } else {
      return tmp;
    }
  }

  factory MemDetailRepository.initialize(Table table) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = MemDetailRepository._(table);
      _instance = tmp;
    }
    return tmp;
  }

  factory MemDetailRepository.withMock(MemDetailRepository mock) {
    _instance = mock;
    return mock;
  }

  static clear() => _instance = null;
}

const memMemoName = 'memo';

enum MemDetailType {
  memo,
}
