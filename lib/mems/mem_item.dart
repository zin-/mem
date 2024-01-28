import 'package:mem/core/mem_item.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

class SavedMemItem extends MemItem with SavedDatabaseTupleMixin<int> {
  @override
  int get memId => super.memId as int;

  SavedMemItem(super.memId, super.type, super.value);

  @override
  SavedMemItem copiedWith({
    int Function()? memId,
    dynamic Function()? value,
  }) =>
      SavedMemItem(
        memId == null ? this.memId : memId(),
        type,
        value == null ? this.value : value(),
      )..copiedFrom(this);

  @override
  String toString() => "Saved${super.toString()}${unpack()}";
}
