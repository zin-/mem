import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/table_definitions/base.dart';
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

  MemNotificationEntity.fromV1(MemNotification v1)
      : super(v1.memId, v1.type, v1.time, v1.message);

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

  SavedMemNotificationEntity.fromV1(
    SavedMemNotification v1,
  ) : this.fromMap(
          MemNotificationEntity.fromV1(v1).toMap
            ..addAll(
              {
                defPkId.name: v1.id,
                defColCreatedAt.name: v1.createdAt,
                defColUpdatedAt.name: v1.updatedAt,
                defColArchivedAt.name: v1.archivedAt
              },
            ),
        );

  SavedMemNotification toV1() =>
      SavedMemNotification(memId, type, time, message)
        ..id = id
        ..createdAt = createdAt
        ..updatedAt = updatedAt
        ..archivedAt = archivedAt;
}
