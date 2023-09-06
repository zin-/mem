import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';

class MemNotificationEntity extends DatabaseTupleEntity {
  final int memId;
  final int time;
  final String type;
  final String message;

  MemNotificationEntity(
    this.memId,
    this.type,
    this.time,
    this.message,
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  ) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  MemNotificationEntity.fromMap(Map<String, dynamic> valueMap)
      : memId = valueMap[memIdFkDef.name],
        type = valueMap[memNotificationTypeColDef.name],
        time = valueMap[timeColDef.name],
        message = valueMap[memNotificationMessageColDef.name],
        super.fromMap(valueMap);

  @override
  Map<String, dynamic> toMap() => {
        memIdFkDef.name: memId,
        memNotificationTypeColDef.name: type,
        timeColDef.name: time,
        memNotificationMessageColDef.name: message,
      }..addAll(super.toMap());
}
