import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/repositories/database_tuple_entity.dart';

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
      : memId = valueMap[defFkMemNotificationsMemId.name],
        type = valueMap[defColMemNotificationsType.name],
        time = valueMap[defColMemNotificationsTime.name],
        message = valueMap[defColMemNotificationsMessage.name],
        super.fromMap(valueMap);

  @override
  Map<String, dynamic> toMap() => {
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: type,
        defColMemNotificationsTime.name: time,
        defColMemNotificationsMessage.name: message,
      }..addAll(super.toMap());
}
