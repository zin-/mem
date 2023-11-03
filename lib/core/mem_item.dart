import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

import 'entity_value.dart';

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

  MemItem toV1() => MemItem(
        type: type,
        memId: memId,
        value: value,
      );

  factory MemItemV2.fromV1(MemItem v1) => v1.isSaved()
      ? SavedMemItemV2.fromV1(v1)
      : MemItemV2(
          v1.memId,
          v1.type,
          v1.value,
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

  @override
  MemItem toV1() => MemItem(
        type: type,
        memId: memId,
        value: value,
        id: id as int,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archivedAt: archivedAt,
      );

  factory SavedMemItemV2.fromV1(MemItem v1) => SavedMemItemV2(
        v1.memId as int,
        v1.type,
        v1.value,
      )
        ..id = v1.id as I
        ..createdAt = v1.createdAt as DateTime
        ..updatedAt = v1.updatedAt
        ..archivedAt = v1.archivedAt;
}

class MemItem extends EntityValue {
  int? memId;
  final MemItemType type;
  dynamic value;

  MemItem({
    this.memId,
    required this.type,
    this.value,
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  @override
  String toString() =>
      {
        'memId': memId,
        'MemItemType': type,
        'value': value,
      }.toString() +
      super.toString();
}
