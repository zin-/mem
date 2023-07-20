import 'entity_value.dart';

enum MemItemType {
  memo,
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
