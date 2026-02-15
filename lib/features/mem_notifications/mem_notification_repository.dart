import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'mem_notification.dart';
import 'mem_notification_entity.dart';

// @Deprecated('MemNotificationRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class MemNotificationRepository extends DatabaseTupleRepository<
    MemNotificationEntityV1,
    SavedMemNotificationEntityV1,
    MemNotification,
    int,
    MemNotificationEntity> {
  @override
  SavedMemNotificationEntityV1 pack(Map<String, dynamic> map) =>
      SavedMemNotificationEntityV1(map);

  @override
  MemNotificationEntity packV2(dynamic tuple) => MemNotificationEntity(
        tuple.memId,
        MemNotificationType.fromName(tuple.type),
        tuple.time,
        tuple.message,
        tuple.id,
        tuple.createdAt,
        tuple.updatedAt,
        tuple.archivedAt,
      );

  @override
  Future<List<SavedMemNotificationEntityV1>> ship({
    int? memId,
    Iterable<int>? memIdsIn,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      super.ship(
        condition: And(
          [
            if (memId != null) Equals(defFkMemNotificationsMemId, memId),
            if (memIdsIn != null) In(defFkMemNotificationsMemId.name, memIdsIn),
            if (condition != null) condition, // coverage:ignore-line
          ],
        ),
        groupBy: groupBy,
        orderBy: orderBy,
        offset: offset,
        limit: limit,
      );

  @override
  Future<List<SavedMemNotificationEntityV1>> waste({
    int? memId,
    MemNotificationType? type,
    Condition? condition,
  }) =>
      super.waste(
        condition: And(
          [
            if (memId != null) Equals(defFkMemNotificationsMemId, memId),
            if (type != null) Equals(defColMemNotificationsType, type.name),
            if (condition != null) condition, // coverage:ignore-line
          ],
        ),
      );

  static MemNotificationRepository? _instance;
  factory MemNotificationRepository({MemNotificationRepository? mock}) =>
      _instance ??= mock ?? MemNotificationRepository._();
  MemNotificationRepository._()
      : super(databaseDefinition, defTableMemNotifications);
}
