import 'package:mem/mems/mem_item.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class MemItemEntity extends MemItem with Entity, Copyable<MemItemEntity> {
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
  Map<String, dynamic> get toMap => {
        defFkMemItemsMemId.name: memId,
        defColMemItemsType.name: type.name,
        defColMemItemsValue.name: value,
      };

  @override
  MemItemEntity copiedWith({
    int Function()? memId,
    dynamic Function()? value,
  }) =>
      MemItemEntity(
        memId == null ? this.memId : memId(),
        type,
        value == null ? this.value : value(),
      );
}

class SavedMemItemEntity extends MemItemEntity with DatabaseTupleEntity<int> {
  SavedMemItemEntity.fromMap(Map<String, dynamic> map) : super.fromMap(map) {
    withMap(map);
  }

  @override
  MemItemEntity copiedWith({
    int Function()? memId,
    dynamic Function()? value,
  }) =>
      SavedMemItemEntity.fromMap(
        toMap
          ..addAll(
            super
                .copiedWith(
                  memId: memId,
                  value: value,
                )
                .toMap,
          ),
      );
}

class MemItemEntityV2 with EntityV2<MemItem> {
  MemItemEntityV2(MemItem value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        defFkMemItemsMemId.name: value.memId,
        defColMemItemsType.name: value.type.name,
        defColMemItemsValue.name: value.value,
      };

  @override
  MemItemEntityV2 updatedWith(MemItem Function(MemItem v) update) =>
      MemItemEntityV2(update(value));

  MemItemEntityV2 copiedWith({
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

  factory MemItemEntityV2.fromV1(MemItemEntity v1) {
    if (v1 is SavedMemItemEntity) {
      return SavedMemItemEntityV2.fromV1(v1);
    } else {
      return MemItemEntityV2(v1);
    }
  }

  MemItemEntity toV1() => MemItemEntity(value.memId, value.type, value.value);
}

class SavedMemItemEntityV2 extends MemItemEntityV2
    with DatabaseTupleEntityV2<int, MemItem> {
  SavedMemItemEntityV2(Map<String, dynamic> map)
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
  SavedMemItemEntityV2 updatedWith(MemItem Function(MemItem v) update) =>
      SavedMemItemEntityV2(toMap..addAll(super.updatedWith(update).toMap));

  factory SavedMemItemEntityV2.fromV1(SavedMemItemEntity v1) =>
      SavedMemItemEntityV2(v1.toMap);

  @override
  SavedMemItemEntity toV1() => SavedMemItemEntity.fromMap(toMap);
}
