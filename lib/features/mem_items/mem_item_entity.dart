import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart' as drift_database;
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class MemItemEntityV1 with EntityV1<MemItem> {
  MemItemEntityV1(MemItem value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        'memId': value.memId,
        'type': value.type.name,
        'value': value.value,
      };

  @override
  MemItemEntityV1 updatedWith(MemItem Function(MemItem v) update) =>
      MemItemEntityV1(update(value));

  MemItemEntityV1 copiedWith({
    int Function()? memId,
    dynamic Function()? value,
  }) =>
      updatedWith(
        (v) => MemItem(
          memId == null ? v.memId : memId(),
          v.type,
          value == null ? v.value : value(),
        ),
      );

  MemItem toDomain() => MemItem(
        value.memId,
        value.type,
        value.value,
      );
}

class SavedMemItemEntityV1 extends MemItemEntityV1
    with DatabaseTupleEntityV1<int, MemItem> {
  SavedMemItemEntityV1(Map<String, dynamic> map)
      : super(_memItemFromMap(map)) {
    withBaseColumns(map);
  }

  SavedMemItemEntityV1.fromRow(dynamic row) : super(_memItemFromRow(row)) {
    withBaseColumns(row);
  }

  static MemItem _memItemFromMap(Map<String, dynamic> map) => MemItem(
        map['memId'] ?? map['mems_id'],
        MemItemType.values.firstWhere(
          (element) => element.name == map['type'],
        ),
        map['value'],
      );

  static MemItem _memItemFromRow(dynamic row) => MemItem(
        row.memId,
        MemItemType.values.firstWhere(
          (element) => element.name == row.type,
        ),
        row.value,
      );

  @override
  SavedMemItemEntityV1 updatedWith(MemItem Function(MemItem v) update) =>
      SavedMemItemEntityV1(_savedRowFrom(this, update(value)));

  factory SavedMemItemEntityV1.fromEntityV2(MemItemEntity entity) =>
      SavedMemItemEntityV1.fromRow(_MemItemEntityRow(entity));

  MemItemEntity toEntityV2() => MemItemEntity(
        value.memId,
        value.type,
        value.value,
        id,
        createdAt,
        updatedAt,
        archivedAt,
      );
}

Map<String, Object?> _savedRowFrom(
  SavedMemItemEntityV1 saved,
  MemItem value,
) =>
    {
      'id': saved.id,
      'memId': value.memId,
      'type': value.type.name,
      'value': value.value,
      'createdAt': saved.createdAt,
      'updatedAt': saved.updatedAt,
      'archivedAt': saved.archivedAt,
    };

class MemItemEntity implements Entity<int> {
  final MemId memId;
  final MemItemType type;
  final String value;

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  MemItemEntity(
    this.memId,
    this.type,
    this.value,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  );

  factory MemItemEntity.fromTuple(dynamic row) => MemItemEntity(
        row.memId,
        MemItemType.values.firstWhere(
          (element) => element.name == row.type,
        ),
        row.value,
        row.id,
        row.createdAt,
        row.updatedAt,
        row.archivedAt,
      );
}

drift_database.MemItemsCompanion convertIntoMemItemsInsertable(
  MemItem domain,
  DateTime createdAt,
) =>
    drift_database.MemItemsCompanion(
      type: Value(domain.type.name),
      value: Value(domain.value),
      memId: Value(domain.memId ?? 0),
      createdAt: Value(createdAt),
    );
drift_database.MemItemsCompanion convertIntoMemItemsUpdateable(
  MemItemEntity entity,
) =>
    drift_database.MemItemsCompanion(
      type: Value(entity.type.name),
      value: Value(entity.value),
      memId: Value(entity.memId ?? 0),
      updatedAt: Value(DateTime.now()),
      archivedAt: Value(entity.archivedAt),
    );

class _MemItemEntityRow {
  final MemItemEntity entity;

  _MemItemEntityRow(this.entity);

  int get id => entity.id;
  int get memId => entity.memId!;
  String get type => entity.type.name;
  String get value => entity.value;
  DateTime get createdAt => entity.createdAt;
  DateTime? get updatedAt => entity.updatedAt;
  DateTime? get archivedAt => entity.archivedAt;
}
