import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

import 'mem_notification.dart';

class MemNotificationEntity with Entity<MemNotification> {
  MemNotificationEntity(MemNotification value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        defFkMemNotificationsMemId.name: value.memId,
        defColMemNotificationsType.name: value.type.name,
        defColMemNotificationsTime.name: value.time,
        defColMemNotificationsMessage.name: value.message,
      };

  @override
  MemNotificationEntity updatedWith(
          MemNotification Function(MemNotification v) update) =>
      MemNotificationEntity(update(value));
}

class SavedMemNotificationEntity extends MemNotificationEntity
    with DatabaseTupleEntity<int, MemNotification> {
  SavedMemNotificationEntity(Map<String, dynamic> map)
      : super(
          MemNotification.by(
            map[defFkMemNotificationsMemId.name],
            MemNotificationType.fromName(map[defColMemNotificationsType.name]),
            map[defColMemNotificationsTime.name],
            map[defColMemNotificationsMessage.name],
          ),
        ) {
    withMap(map);
  }

  @override
  SavedMemNotificationEntity updatedWith(
          MemNotification Function(MemNotification v) update) =>
      SavedMemNotificationEntity(
          toMap..addAll(super.updatedWith(update).toMap));
}
