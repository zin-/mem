import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/features/logger/log_service.dart';

import 'mem_notification.dart';
import 'mem_notification_entity.dart';

class MemNotificationRepositoryV2 extends DatabaseTupleRepositoryV2<
    MemNotificationEntity, SavedMemNotificationEntityV2> {
  MemNotificationRepositoryV2()
      : super(databaseDefinition, defTableMemNotifications);

  @override
  SavedMemNotificationEntityV2 pack(Map<String, dynamic> map) =>
      SavedMemNotificationEntityV2(map);

  @override
  Future<List<SavedMemNotificationEntityV2>> ship({
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

  Future<Iterable<SavedMemNotificationEntityV2>> archiveBy({
    int? memId,
    Condition? condition,
    DateTime? archivedAt,
  }) =>
      v(
        () async => await ship(memId: memId, condition: condition).then((v) =>
            Future.wait(v.map((e) => archive(e, archivedAt: archivedAt)))),
        {
          'memId': memId,
          'condition': condition,
          'archivedAt': archivedAt,
        },
      );

  Future<Iterable<SavedMemNotificationEntityV2>> unarchiveBy({
    int? memId,
    Condition? condition,
    DateTime? updatedAt,
  }) =>
      v(
        () async => await ship(memId: memId, condition: condition).then((v) =>
            Future.wait(v.map((e) => unarchive(e, updatedAt: updatedAt)))),
        {
          'memId': memId,
          'condition': condition,
          'updatedAt': updatedAt,
        },
      );

  @override
  Future<List<SavedMemNotificationEntityV2>> waste({
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
}
