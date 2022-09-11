import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/repository.dart';

const memDetailTypeColumnName = 'type';

final memDetailTableDefinition = DefT(
  'mem_details',
  [
    DefPK(idColumnName, TypeC.integer, autoincrement: true),
    DefC(memDetailTypeColumnName, TypeC.text),
    DefFK(memTableDefinition),
    ...defaultColumnDefinitions,
  ],
);

class MemDetailEntity extends DatabaseTableEntity {
  MemDetailType type;

  MemDetailEntity.fromMap(super.valueMap)
      : type = valueMap[memDetailTypeColumnName],
        super.fromMap();
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
