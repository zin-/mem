import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/database.dart' as drift_database;
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class MemItemEntityV1 with EntityV1<MemItem> {
  MemItemEntityV1(MemItem value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        defFkMemItemsMemId.name: value.memId,
        defColMemItemsType.name: value.type.name,
        defColMemItemsValue.name: value.value,
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
      : super(
          MemItem(
            map[defFkMemItemsMemId.name],
            MemItemType.values.firstWhere(
                (element) => element.name == map[defColMemItemsType.name]),
            map[defColMemItemsValue.name],
          ),
        ) {
    withMap(map);
  }

  @override
  SavedMemItemEntityV1 updatedWith(MemItem Function(MemItem v) update) =>
      SavedMemItemEntityV1(toMap..addAll(super.updatedWith(update).toMap));

  factory SavedMemItemEntityV1.fromEntityV2(MemItemEntity entity) =>
      SavedMemItemEntityV1(
        {
          defFkMemItemsMemId.name: entity.memId,
          defColMemItemsType.name: entity.type.name,
          defColMemItemsValue.name: entity.value,
          defPkId.name: entity.id,
          defColCreatedAt.name: entity.createdAt,
          defColUpdatedAt.name: entity.updatedAt,
          defColArchivedAt.name: entity.archivedAt,
        },
      );

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
}

convertIntoMemItemsInsertable(MemItem domain, DateTime createdAt) =>
    drift_database.MemItemsCompanion(
      type: Value(domain.type.name),
      value: Value(domain.value),
      memId: Value(domain.memId ?? 0),
      createdAt: Value(createdAt),
    );
convertIntoMemItemsUpdateable(MemItemEntity entity) =>
    drift_database.MemItemsCompanion(
      type: Value(entity.type.name),
      value: Value(entity.value),
      memId: Value(entity.memId ?? 0),
      updatedAt: Value(DateTime.now()),
      archivedAt: Value(entity.archivedAt),
    );
