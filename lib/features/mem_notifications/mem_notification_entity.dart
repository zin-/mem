import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

import 'mem_notification.dart';

class MemNotificationEntityV1 with EntityV1<MemNotification> {
  MemNotificationEntityV1(MemNotification value) {
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
  MemNotificationEntityV1 updatedWith(
          MemNotification Function(MemNotification v) update) =>
      MemNotificationEntityV1(update(value));
}

class SavedMemNotificationEntityV1 extends MemNotificationEntityV1
    with DatabaseTupleEntityV1<int, MemNotification> {
  SavedMemNotificationEntityV1(Map<String, dynamic> map)
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
  SavedMemNotificationEntityV1 updatedWith(
          MemNotification Function(MemNotification v) update) =>
      SavedMemNotificationEntityV1(
          toMap..addAll(super.updatedWith(update).toMap));
}

class MemNotificationEntity implements Entity<int> {
  final MemId memId;
  final MemNotificationType type;
  final int? time;
  final String message;

  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  MemNotificationEntity(
    this.memId,
    this.type,
    this.time,
    this.message,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  );
}
