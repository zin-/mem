import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';

void main() {
  group('MemNotificationEntity', () {
    test('SavedMemNotificationEntityV1 map fallback and toEntityV2', () {
      final createdAt = DateTime(2024, 1, 1);
      final updatedAt = DateTime(2024, 1, 2);
      final archivedAt = DateTime(2024, 1, 3);
      final saved = SavedMemNotificationEntityV1({
        'id': 1,
        'mems_id': 2,
        'type': MemNotificationType.repeat.name,
        'time_of_day_seconds': 600,
        'message': 'm',
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      });

      expect(saved.value.memId, 2);
      expect(saved.value.time, 600);
      expect(saved.toEntityV2().id, 1);
      expect(saved.toEntityV2().type, MemNotificationType.repeat);
    });

    test('fromEntityV2 and updatedWith', () {
      final now = DateTime(2024, 2, 1);
      final saved = SavedMemNotificationEntityV1.fromEntityV2(
        MemNotificationEntity(
          3,
          MemNotificationType.afterActStarted,
          1200,
          'before',
          4,
          now,
          now,
          null,
        ),
      );
      final updated = saved.updatedWith(
        (v) => MemNotification.by(v.memId, v.type, v.time, 'after'),
      );

      expect(updated.id, 4);
      expect(updated.value.message, 'after');
      expect(updated.createdAt, now);
    });

    test('fromTuple, toDomain, insertable and updateable', () {
      final now = DateTime(2024, 3, 1);
      final entity = MemNotificationEntity.fromTuple(
        _FakeRow(
          id: 5,
          memId: 6,
          type: MemNotificationType.repeatByNDay.name,
          timeOfDaySeconds: 2,
          message: 'tuple',
          createdAt: now,
          updatedAt: now,
          archivedAt: null,
        ),
      );
      expect(entity.id, 5);
      expect(entity.type, MemNotificationType.repeatByNDay);
      expect(entity.toDomain().message, 'tuple');

      final insertable = convertIntoMemRepeatedNotificationsInsertable(
        MemNotification.by(7, MemNotificationType.repeat, 900, 'ins'),
        createdAt: now,
      );
      expect(insertable.memId.value, 7);
      expect(insertable.timeOfDaySeconds.value, 900);
      expect(insertable.type.value, MemNotificationType.repeat.name);
      expect(insertable.createdAt.value, now);

      final updateable = convertIntoMemRepeatedNotificationsUpdateable(
        MemNotificationEntity(
          null,
          MemNotificationType.repeatByDayOfWeek,
          null,
          'upd',
          8,
          now,
          null,
          now,
        ),
      );
      expect(updateable.memId.value, 0);
      expect(updateable.timeOfDaySeconds.value, 0);
      expect(updateable.type.value, MemNotificationType.repeatByDayOfWeek.name);
      expect(updateable.message.value, 'upd');
      expect(updateable.archivedAt.value, now);
      expect(updateable.updatedAt.value, isNotNull);
    });
  });
}

class _FakeRow {
  final int id;
  final int memId;
  final String type;
  final int? timeOfDaySeconds;
  final String message;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  _FakeRow({
    required this.id,
    required this.memId,
    required this.type,
    required this.timeOfDaySeconds,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });
}
