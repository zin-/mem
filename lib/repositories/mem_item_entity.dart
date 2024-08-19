import 'package:mem/core/mem_item.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/mems/mem_item.dart';

class MemItemEntity extends MemItemV2 with Entity {
  MemItemEntity(super.memId, super.type, super.value);

  MemItemEntity.fromMap(Map<String, dynamic> map)
      : super(
          map[defFkMemItemsMemId.name],
          MemItemType.values.firstWhere(
            (v) => v.name == map[defColMemItemsType.name],
          ),
          map[defColMemItemsValue.name],
        );

  @override
  Entity copiedWith({
    int Function()? memId,
    MemItemType Function()? type,
    dynamic Function()? value,
  }) =>
      MemItemEntity(
        memId == null ? this.memId : memId(),
        type == null ? this.type : type(),
        value == null ? this.value : value(),
      );

  @override
  Map<String, dynamic> get toMap => {
        defFkMemItemsMemId.name: memId,
        defColMemItemsType.name: type.name,
        defColMemItemsValue.name: value,
      };
}

class SavedMemItemEntity extends MemItemEntity with DatabaseTupleEntity<int> {
  SavedMemItemEntity.fromMap(Map<String, dynamic> map) : super.fromMap(map) {
    withMap(map);
  }

  SavedMemItemEntity.fromV1(SavedMemItem savedMemItem)
      : this.fromMap(
          MemItemEntity(
                  savedMemItem.memId, savedMemItem.type, savedMemItem.value)
              .toMap
            ..addAll(
              {
                defPkId.name: savedMemItem.id,
                defColCreatedAt.name: savedMemItem.createdAt,
                defColUpdatedAt.name: savedMemItem.updatedAt,
                defColArchivedAt.name: savedMemItem.archivedAt
              },
            ),
        );

  SavedMemItem toV1() => SavedMemItem(memId, type, value)
    ..id = id
    ..createdAt = createdAt
    ..updatedAt = updatedAt
    ..archivedAt = archivedAt;

  @override
  SavedMemItemEntity copiedWith({
    int Function()? memId,
    MemItemType Function()? type,
    dynamic Function()? value,
  }) =>
      SavedMemItemEntity.fromMap(
        toMap
          ..addAll(
            super
                .copiedWith(
                  memId: memId,
                  type: type,
                  value: value,
                )
                .toMap,
          ),
      );
}
