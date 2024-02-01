import 'package:mem/framework/repository/entity.dart';

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

  @override
  String toString() => "${super.toString()}: ${{
        "memId": memId,
        "type": type,
        "value": value,
      }}";
}
