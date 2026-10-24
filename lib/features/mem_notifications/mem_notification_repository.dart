import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
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

  MemNotificationRepository._();

  factory MemNotificationRepository({MemNotificationRepository? mock}) {
    if (mock != null) {
      Singleton.override<MemNotificationRepository>(mock);
      return mock;
    }
    return Singleton.of(() => MemNotificationRepository._());
  }
}
