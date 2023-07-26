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

  Future<Iterable<MemNotification>> shipByMemIdAndAfterActStarted(int memId) =>
      v(
        () => super.ship(And([
          Equals(memIdFkDef.name, memId),
          Equals(
            memNotificationTypeColDef.name,
            MemNotificationType.afterActStarted.name,
          ),
        ])),
        memId,
      );

  @override
  MemNotification pack(Map<String, dynamic> unpackedPayload) {
    final entity = MemNotificationEntity.fromMap(unpackedPayload);

    return MemNotification(
      MemNotificationType.fromName(entity.type),
      entity.time,
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
      payload.time!,
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

  factory MemNotificationRepository([Table? table]) =>
      _instance ??= _instance = MemNotificationRepository._(table!);

  static resetWith(MemNotificationRepository? instance) => _instance = instance;
}
