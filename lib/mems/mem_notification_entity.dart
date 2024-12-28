import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

import 'mem_notification.dart';

class MemNotificationEntityV2 with EntityV2<MemNotification> {
  MemNotificationEntityV2(MemNotification value) {
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
  MemNotificationEntityV2 updatedWith(
          MemNotification Function(MemNotification v) update) =>
      MemNotificationEntityV2(update(value));
}

class SavedMemNotificationEntityV2 extends MemNotificationEntityV2
    with DatabaseTupleEntityV2<int, MemNotification> {
  SavedMemNotificationEntityV2(Map<String, dynamic> map)
      : super(
          MemNotification(
            map[defFkMemNotificationsMemId.name],
            MemNotificationType.fromName(map[defColMemNotificationsType.name]),
            map[defColMemNotificationsTime.name],
            map[defColMemNotificationsMessage.name],
          ),
        ) {
    withMap(map);

    entityTableRelations[MemNotificationEntityV2] ??= defTableMemNotifications;
  }

  @override
  SavedMemNotificationEntityV2 updatedWith(
          MemNotification Function(MemNotification v) update) =>
      SavedMemNotificationEntityV2(
          toMap..addAll(super.updatedWith(update).toMap));
}
