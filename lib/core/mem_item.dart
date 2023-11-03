import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

enum MemItemType {
  memo,
}

class MemItemV2 extends Entity {
  // 未保存のMemに紐づくMemItemはmemIdをintで持つことができないため暫定的にnullableにしている
  final int? memId;
  final MemItemType type;
  final dynamic value;

  MemItemV2(this.memId, this.type, this.value);

  MemItemV2 copiedWith({
    int Function()? memId,
    dynamic Function()? value,
  }) =>
      MemItemV2(
        memId == null ? this.memId : memId(),
        type,
        value == null ? this.value : value(),
      );
}

class SavedMemItemV2<I> extends MemItemV2 with SavedDatabaseTupleMixin<I> {
  @override
  int get memId => super.memId as int;

  SavedMemItemV2(super.memId, super.type, super.value);

  @override
  SavedMemItemV2<I> copiedWith({
    int Function()? memId,
    dynamic Function()? value,
  }) =>
      SavedMemItemV2(
        memId == null ? this.memId : memId(),
        type,
        value == null ? this.value : value(),
      )..copiedFrom(this);
}
