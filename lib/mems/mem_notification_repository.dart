import 'package:mem/core/date_and_time/time_of_day.dart';
import 'package:mem/core/errors.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/database/table_definitions/mem_notifications.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_notification_entity.dart';
import 'package:mem/repositories/i/_database_tuple_repository_v2.dart';
import 'package:mem/repositories/i/conditions.dart';

class MemNotificationRepository
    extends DatabaseTupleRepository<MemNotificationEntity, MemNotification> {
  Future<Iterable<MemNotification>> shipByMemId(int memId) => v(
        () => super.ship(Equals(memIdFkDef.name, memId)),
        memId,
      );

  Future<Iterable<MemNotification>> wasteByMemId(int memId) => v(
        () => super.waste(Equals(memIdFkDef.name, memId)),
        memId,
      );

  @override
  MemNotification pack(Map<String, dynamic> unpackedPayload) {
    final entity = MemNotificationEntity.fromMap(unpackedPayload);

    return MemNotification(
      MemNotificationType.fromName(entity.type),
      TimeOfDay.fromSeconds(entity.time),
      entity.message,
      memId: entity.memId,
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      archivedAt: entity.archivedAt,
    );
  }

  @override
  UnpackedPayload unpack(MemNotification payload) {
    final entity = MemNotificationEntity(
      payload.memId!,
      payload.type.name,
      payload.timeOfDay.toSeconds(),
      payload.message,
      payload.id,
      payload.createdAt,
      payload.updatedAt,
      payload.archivedAt,
    );

    return entity.toMap();
  }

  MemNotificationRepository._(super.table);

  static MemNotificationRepository? _instance;

  factory MemNotificationRepository([Table? table]) {
    var tmp = _instance;

    if (tmp == null) {
      if (table == null) {
        throw InitializationError();
      } else {
        _instance = tmp = MemNotificationRepository._(table);
      }
    }

    return tmp;
  }
}
