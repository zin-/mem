import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/database_tuple_repository.dart';
import 'package:mem/repositories/conditions/conditions.dart';

class MemNotificationRepository extends DatabaseTupleRepository<
    MemNotificationV2, SavedMemNotificationV2<int>, int> {
  Future<Iterable<SavedMemNotificationV2<int>>> shipByMemId(int memId) => v(
        () => super.ship(Equals(defFkMemNotificationsMemId.name, memId)),
        memId,
      );

  Future<Iterable<SavedMemNotificationV2<int>>> shipByMemIdAndAfterActStarted(
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

  Future<Iterable<SavedMemNotificationV2<int>>> wasteByMemId(int memId) => v(
        () => super.waste(Equals(defFkMemNotificationsMemId.name, memId)),
        memId,
      );

  @override
  SavedMemNotificationV2<int> pack(Map<String, dynamic> tuple) =>
      SavedMemNotificationV2<int>(
        tuple[defFkMemNotificationsMemId.name],
        MemNotificationType.fromName(tuple[defColMemNotificationsType.name]),
        tuple[defColMemNotificationsTime.name],
        tuple[defColMemNotificationsMessage.name],
      )..pack(tuple);

  @override
  Map<String, dynamic> unpack(MemNotificationV2 entity) {
    final map = {
      defFkMemNotificationsMemId.name: entity.memId,
      defColMemNotificationsType.name: entity.type.name,
      defColMemNotificationsTime.name: entity.time,
      defColMemNotificationsMessage.name: entity.message,
    };

    if (entity is SavedMemNotificationV2) {
      map.addAll(entity.unpack());
    }

    return map;
  }

  MemNotificationRepository._() : super(defTableMemNotifications);

  static MemNotificationRepository? _instance;

  factory MemNotificationRepository() =>
      _instance ??= MemNotificationRepository._();
}
