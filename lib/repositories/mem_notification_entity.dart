import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

class MemNotificationEntity extends MemNotification
    with Entity, Copyable<MemNotificationEntity> {
  MemNotificationEntity(super.memId, super.type, super.time, super.message)
      : super();

  MemNotificationEntity.fromMap(Map<String, dynamic> map)
      : super(
          map[defFkMemNotificationsMemId.name],
          MemNotificationType.fromName(map[defColMemNotificationsType.name]),
          map[defColMemNotificationsTime.name],
          map[defColMemNotificationsMessage.name],
        );

  static MemNotificationEntity initialByType(
    int? memId,
    MemNotificationType type, {
    int? Function()? time,
  }) {
    final core = MemNotification.initialByType(memId, type, time: time);
    return MemNotificationEntity(memId, type, core.time, core.message);
  }

  @override
  Map<String, dynamic> get toMap => {
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: type.name,
        defColMemNotificationsTime.name: time,
        defColMemNotificationsMessage.name: message,
      };

  @override
  MemNotificationEntity copiedWith({
    int? Function()? memId,
    int? Function()? time,
    String Function()? message,
  }) =>
      MemNotificationEntity(
        memId == null ? this.memId : memId(),
        type,
        time == null ? this.time : time(),
        message == null ? this.message : message(),
      );
}

class SavedMemNotificationEntity extends MemNotificationEntity
    with DatabaseTupleEntity<int> {
  SavedMemNotificationEntity.fromMap(
    Map<String, dynamic> map,
  ) : super.fromMap(map) {
    withMap(map);
  }

  @override
  SavedMemNotificationEntity copiedWith({
    int? Function()? memId,
    int? Function()? time,
    String Function()? message,
  }) =>
      SavedMemNotificationEntity.fromMap(
        toMap
          ..addAll(
            super
                .copiedWith(
                  memId: memId,
                  time: time,
                  message: message,
                )
                .toMap,
          ),
      );
}
