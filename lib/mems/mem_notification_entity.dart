import 'package:mem/mems/mem_notification.dart';
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

  factory MemNotificationEntityV2.fromV1(MemNotification v1) {
    if (v1 is SavedMemNotificationEntity) {
      return SavedMemNotificationEntityV2(v1.toMap);
    } else {
      return MemNotificationEntityV2(v1);
    }
  }

  MemNotificationEntity toV1() =>
      MemNotificationEntity(value.memId, value.type, value.time, value.message);
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
  }

  @override
  SavedMemNotificationEntityV2 updatedWith(
          MemNotification Function(MemNotification v) update) =>
      SavedMemNotificationEntityV2(
          toMap..addAll(super.updatedWith(update).toMap));

  @override
  SavedMemNotificationEntity toV1() =>
      SavedMemNotificationEntity.fromMap(toMap);

  factory SavedMemNotificationEntityV2.fromV1(SavedMemNotificationEntity v1) {
    return SavedMemNotificationEntityV2(v1.toMap);
  }
}
