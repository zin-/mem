import 'package:mem/framework/repository/entity.dart';

enum MemItemType {
  memo,
}

class MemItemV2 {
  final int? memId;
  final MemItemType type;
  final dynamic value;

  MemItemV2(this.memId, this.type, this.value);

  factory MemItemV2.memo(int? memId) => MemItemV2(memId, MemItemType.memo, "");
}

class MemItem extends EntityV1 {
  // 未保存のMemに紐づくMemItemはmemIdをintで持つことができないため暫定的にnullableにしている
  final int? memId;
  final MemItemType type;
  final dynamic value;

  MemItem(this.memId, this.type, this.value);

  factory MemItem.memo(int? memId) => MemItem(memId, MemItemType.memo, "");

  MemItem copiedWith({
    int Function()? memId,
    dynamic Function()? value,
  }) =>
      MemItem(
        memId == null ? this.memId : memId(),
        type,
        value == null ? this.value : value(),
      );

  @override
  String toString() => "${super.toString()}: ${{
        "memId": memId,
        "type": type,
        "value": value,
      }}";
}
