import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class MemItemEntityV2 with Entity<MemItem> {
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
}

class SavedMemItemEntityV2 extends MemItemEntityV2
    with DatabaseTupleEntity<int, MemItem> {
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
}
