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
