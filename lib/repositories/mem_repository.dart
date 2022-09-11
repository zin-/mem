import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/repositories/repository.dart';

const memNameColumnName = 'name';

final memTableDefinition = DefT(
  'mems',
  [
    DefPK(idColumnName, TypeC.integer, autoincrement: true),
    DefC(memNameColumnName, TypeC.text),
    ...defaultColumnDefinitions
  ],
);

class MemEntity extends DatabaseTableEntity {
  final String name;

  MemEntity({
    required this.name,
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

  @override
  MemEntity.fromMap(Map<String, dynamic> valueMap)
      : name = valueMap[memNameColumnName],
        super.fromMap(valueMap);

  @override
  Map<String, dynamic> toMap() => {
        memNameColumnName: name,
      }..addAll(super.toMap());
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
