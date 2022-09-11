import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/repositories/repository.dart';

const memNameColumnName = 'name';

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

class MemRepositoryV2 extends DatabaseTableRepository<MemEntity> {
  @override
  MemEntity fromMap(Map<String, dynamic> valueMap) =>
      MemEntity.fromMap(valueMap);

  static MemRepositoryV2? _instance;

  MemRepositoryV2._(super.table);

  factory MemRepositoryV2() {
    var tmp = _instance;
    if (tmp == null) {
      throw Exception('Call initialize'); // coverage:ignore-line
    } else {
      return tmp;
    }
  }

  factory MemRepositoryV2.initialize(Table memTable) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = MemRepositoryV2._(memTable);
      _instance = tmp;
    }
    return tmp;
  }

  factory MemRepositoryV2.withMock(MemRepositoryV2 mock) {
    _instance = mock;
    return mock;
  }

  static clear() => _instance = null;
}

final memTableDefinition = DefT(
  'mems',
  [
    DefPK('id', TypeC.integer, autoincrement: true),
    DefC(memNameColumnName, TypeC.text),
    ...defaultColumnDefinitions
  ],
);
