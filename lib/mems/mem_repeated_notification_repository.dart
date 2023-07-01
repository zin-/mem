import 'package:mem/core/date_and_time/time_of_day.dart';
import 'package:mem/core/errors.dart';
import 'package:mem/core/mem_repeated_notification.dart';
import 'package:mem/database/table_definitions/mem_repeated_notifications.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_repeated_notification_entity.dart';
import 'package:mem/repositories/i/_database_tuple_repository_v2.dart';
import 'package:mem/repositories/i/conditions.dart';

class MemRepeatedNotificationRepository extends DatabaseTupleRepository<
    MemRepeatedNotificationEntity, MemRepeatedNotification> {
  Future<Iterable<MemRepeatedNotification>> shipByMemId(int memId) => v(
        () => super.ship(Equals(memIdFkDef.name, memId)),
        memId,
      );

  Future<Iterable<MemRepeatedNotification>> wasteByMemId(int memId) => v(
        () => super.waste(Equals(memIdFkDef.name, memId)),
        memId,
      );

  @override
  MemRepeatedNotification pack(Map<String, dynamic> unpackedPayload) {
    final entity = MemRepeatedNotificationEntity.fromMap(unpackedPayload);

    return MemRepeatedNotification(
      TimeOfDay.fromSeconds(entity.timeOfDaySeconds),
      memId: entity.memId,
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      archivedAt: entity.archivedAt,
    );
  }

  @override
  UnpackedPayload unpack(MemRepeatedNotification payload) {
    final entity = MemRepeatedNotificationEntity(
      payload.memId!,
      payload.timeOfDay.toSeconds(),
      payload.id,
      payload.createdAt,
      payload.updatedAt,
      payload.archivedAt,
    );

    return entity.toMap();
  }

  MemRepeatedNotificationRepository._(super.table);

  static MemRepeatedNotificationRepository? _instance;

  factory MemRepeatedNotificationRepository([Table? table]) {
    var tmp = _instance;

    if (tmp == null) {
      if (table == null) {
        throw InitializationError();
      } else {
        _instance = tmp = MemRepeatedNotificationRepository._(table);
      }
    }

    return tmp;
  }
}
