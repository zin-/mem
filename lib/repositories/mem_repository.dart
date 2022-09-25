import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/repository.dart';

const memNameColumnName = 'name';
const memDoneAtColumnName = 'doneAt';

final memTableDefinition = DefT(
  'mems',
  [
    DefPK(idColumnName, TypeC.integer, autoincrement: true),
    DefC(memNameColumnName, TypeC.text),
    DefC(memDoneAtColumnName, TypeC.datetime, notNull: false),
    ...defaultColumnDefinitions
  ],
);

class MemEntity extends DatabaseTableEntity {
  String name;
  DateTime? doneAt;

  MemEntity({
    required this.name,
    this.doneAt,
    required int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  @override
  MemEntity.fromMap(Map<String, dynamic> valueMap)
      : name = valueMap[memNameColumnName],
        doneAt = valueMap[memDoneAtColumnName],
        super.fromMap(valueMap);

  @override
  Map<String, dynamic> toMap() => {
        memNameColumnName: name,
        memDoneAtColumnName: doneAt,
      }..addAll(super.toMap());

  Mem toDomain() => Mem(id, name, doneAt, createdAt, updatedAt, archivedAt);

  MemEntity.fromDomain(Mem mem)
      : name = mem.name,
        doneAt = mem.doneAt,
        super(
          id: mem.id,
          createdAt: mem.createdAt,
          updatedAt: mem.updatedAt,
          archivedAt: mem.archivedAt,
        );
}

class MemRepository extends DatabaseTableRepository<MemEntity> {
  @override
  MemEntity fromMap(Map<String, dynamic> valueMap) =>
      MemEntity.fromMap(valueMap);

  MemRepository._(super.table);

  static MemRepository? _instance;

  factory MemRepository() {
    var tmp = _instance;
    if (tmp == null) {
      throw Exception('Call initialize'); // coverage:ignore-line
    } else {
      return tmp;
    }
  }

  factory MemRepository.initialize(Table table) {
    var tmp = MemRepository._(table);

    _instance = tmp;
    return tmp;
  }

  factory MemRepository.withMock(MemRepository mock) {
    _instance = mock;
    return mock;
  }
}
