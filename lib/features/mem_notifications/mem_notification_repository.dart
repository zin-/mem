import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/framework/repository/load_child_spec.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'mem_notification.dart';
import 'mem_notification_entity.dart';

// @Deprecated('MemNotificationRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class MemNotificationRepository extends DatabaseTupleRepository<MemNotification,
    int, MemNotificationEntity> {
  @override
  Future<List<MemNotificationEntity>> shipV2({
    int? memId,
    Iterable<int>? memIdsIn,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
    List<LoadChildSpec>? loadChildren,
  }) =>
      super.shipV2(
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
        loadChildren: loadChildren,
      );

  @override
  Future<List<MemNotificationEntity>> wasteV2({
    int? memId,
    MemNotificationType? type,
    Condition? condition,
  }) =>
      super.wasteV2(
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
