import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart'
    show
        MemNotificationEntity,
        convertIntoMemRepeatedNotificationsInsertable,
        convertIntoMemRepeatedNotificationsUpdateable;
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

// @Deprecated('MemNotificationRepositoryは集約の単位から外れているためMemRepositoryに集約されるべき')
// lintエラーになるためコメントアウト
class MemNotificationRepository extends DriftRepository {
  Future<List<MemNotificationEntity>> ship({
    int? memId,
    Iterable<int>? memIdsIn,
  }) =>
      v(
        () async {
          var query = driftDb.select(driftDb.memRepeatedNotifications);
          if (memId != null) {
            query = query..where((t) => t.memId.equals(memId));
          } else if (memIdsIn != null) {
            query = query..where((t) => t.memId.isIn(memIdsIn));
          }
          final rows = await query.get();
          return rows.map(MemNotificationEntity.fromTuple).toList();
        },
        {
          'memId': memId,
          'memIdsIn': memIdsIn,
        },
      );

  Future<MemNotificationEntity> receive(MemNotification domain) => v(
        () async {
          final inserted =
              await driftDb.into(driftDb.memRepeatedNotifications).insertReturning(
                    convertIntoMemRepeatedNotificationsInsertable(
                      domain,
                      createdAt: DateTime.now(),
                    ),
                  );
          return MemNotificationEntity.fromTuple(inserted);
        },
        {'domain': domain},
      );

  Future<MemNotificationEntity> replace(MemNotificationEntity entity) => v(
        () async {
          final updated =
              await (driftDb.update(driftDb.memRepeatedNotifications)
                    ..where((t) => t.id.equals(entity.id)))
                  .writeReturning(
                    convertIntoMemRepeatedNotificationsUpdateable(entity),
                  );
          return MemNotificationEntity.fromTuple(updated.single);
        },
        {'entity': entity},
      );

  Future<List<MemNotificationEntity>> waste({
    int? memId,
    MemNotificationType? type,
  }) =>
      v(
        () async {
          var query = driftDb.delete(driftDb.memRepeatedNotifications);
          if (memId != null) {
            query = query..where((t) => t.memId.equals(memId));
          }
          if (type != null) {
            query = query..where((t) => t.type.equals(type.name));
          }
          final deleted = await query.goAndReturn();
          return deleted.map(MemNotificationEntity.fromTuple).toList();
        },
        {
          'memId': memId,
          'type': type,
        },
      );

  MemNotificationRepository._();

  factory MemNotificationRepository({MemNotificationRepository? mock}) {
    if (mock != null) {
      Singleton.override<MemNotificationRepository>(mock);
      return mock;
    }
    return Singleton.of(() => MemNotificationRepository._());
  }
}
