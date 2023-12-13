import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';

class MemNotificationRepository extends DatabaseTupleRepository<
    MemNotification, SavedMemNotification<int>, int> {
  Future<Iterable<SavedMemNotification<int>>> shipByMemId(int memId) => v(
        () => super.ship(Equals(defFkMemNotificationsMemId.name, memId)),
        memId,
      );

  Future<Iterable<SavedMemNotification<int>>> shipByMemIdAndAfterActStarted(
          int memId) =>
      v(
        () => super.ship(And([
          Equals(defFkMemNotificationsMemId.name, memId),
          Equals(
            defColMemNotificationsType.name,
            MemNotificationType.afterActStarted.name,
          ),
        ])),
        memId,
      );

  Future<Iterable<SavedMemNotification<int>>> wasteByMemId(int memId) => v(
        () => super.waste(Equals(defFkMemNotificationsMemId.name, memId)),
        memId,
      );

  @override
  SavedMemNotification<int> pack(Map<String, dynamic> tuple) =>
      SavedMemNotification<int>(
        tuple[defFkMemNotificationsMemId.name],
        MemNotificationType.fromName(tuple[defColMemNotificationsType.name]),
        tuple[defColMemNotificationsTime.name],
        tuple[defColMemNotificationsMessage.name],
      )..pack(tuple);

  @override
  Map<String, dynamic> unpack(MemNotification entity) {
    final map = {
      defFkMemNotificationsMemId.name: entity.memId,
      defColMemNotificationsType.name: entity.type.name,
      defColMemNotificationsTime.name: entity.time,
      defColMemNotificationsMessage.name: entity.message,
    };

    if (entity is SavedMemNotification) {
      map.addAll(entity.unpack());
    }

    return map;
  }

  MemNotificationRepository._() : super(defTableMemNotifications);

  static MemNotificationRepository? _instance;

  factory MemNotificationRepository() =>
      _instance ??= MemNotificationRepository._();
}
