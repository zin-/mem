import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/repositories/mem_notification.dart';

class MemNotificationRepository extends DatabaseTupleRepository<MemNotification,
    SavedMemNotification, int> {
  @override
  Future<List<SavedMemNotification>> ship({
    Iterable<int>? memIdsIn,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      v(
        () => super.ship(
          condition: And(
            [
              if (memIdsIn != null)
                In(defFkMemNotificationsMemId.name, memIdsIn),
              if (condition != null) condition, // coverage:ignore-line
            ],
          ),
          groupBy: groupBy,
          orderBy: orderBy,
          offset: offset,
          limit: limit,
        ),
        {
          'memIds': memIdsIn,
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  Future<List<SavedMemNotification>> shipByMemId(
    int memId,
  ) =>
      v(
        () => super
            .ship(condition: Equals(defFkMemNotificationsMemId.name, memId)),
        {
          "memId": memId,
        },
      );

  Future<Iterable<SavedMemNotification>> archiveByMemId(int memId) => v(
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.archive(e))),
        {
          "memId": memId,
        },
      );

  Future<Iterable<SavedMemNotification>> unarchiveByMemId(int memId) => v(
        () async => Future.wait(
            (await shipByMemId(memId)).map((e) => super.unarchive(e))),
        {
          "memId": memId,
        },
      );

  @override
  Future<List<SavedMemNotification>> waste([
    Condition? condition,
    int? memIdIs,
    MemNotificationType? type,
  ]) =>
      v(
        () => super.waste(
          And(
            [
// coverage:ignore-start
              if (condition != null) condition,
// coverage:ignore-end
              if (memIdIs != null)
                Equals(defFkMemNotificationsMemId.name, memIdIs),
              if (type != null)
                Equals(defColMemNotificationsType.name, type.name),
            ],
          ),
        ),
        {
          'condition': condition,
          'memId': memIdIs,
          'type': type,
        },
      );

  @override
  SavedMemNotification pack(Map<String, dynamic> tuple) => SavedMemNotification(
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

  factory MemNotificationRepository() => v(
        () => _instance ??= MemNotificationRepository._(),
      );
}
