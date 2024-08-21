import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/repositories/mem_notification.dart';

class MemNotificationEntity extends MemNotificationV2 with Entity {
  MemNotificationEntity.fromMap(Map<String, dynamic> map)
      : super(
          map[defFkMemNotificationsMemId.name],
          MemNotificationType.fromName(map[defColMemNotificationsType.name]),
          map[defColMemNotificationsTime.name],
          map[defColMemNotificationsMessage.name],
        );

  @override
  Entity copiedWith() {
    // TODO: implement copiedWith
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> get toMap => {
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: type.name,
        defColMemNotificationsTime.name: time,
        defColMemNotificationsMessage.name: message,
      };
}

class SavedMemNotificationEntity extends MemNotificationEntity
    with DatabaseTupleEntity<int> {
  SavedMemNotificationEntity.fromMap(
    Map<String, dynamic> map,
  ) : super.fromMap(map) {
    withMap(map);
  }

  SavedMemNotification toV1() =>
      SavedMemNotification(memId, type, time, message)
        ..id = id
        ..createdAt = createdAt
        ..updatedAt = updatedAt
        ..archivedAt = archivedAt;
}
