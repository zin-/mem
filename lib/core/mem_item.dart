import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

enum MemItemType {
  memo,
}

class MemItem extends EntityV1 {
  // 未保存のMemに紐づくMemItemはmemIdをintで持つことができないため暫定的にnullableにしている
  final int? memId;
  final MemItemType type;
  final dynamic value;

  MemItem(this.memId, this.type, this.value);

  MemItem copiedWith({
    int Function()? memId,
    dynamic Function()? value,
  }) =>
      MemItem(
        memId == null ? this.memId : memId(),
        type,
        value == null ? this.value : value(),
      );
}

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
}
