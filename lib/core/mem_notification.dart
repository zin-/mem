import 'package:mem/core/entity_value.dart';
import 'package:mem/framework/entity.dart';
import 'package:mem/repositories/database_tuple_entity.dart';

class MemNotificationV2 extends Entity {
  final int memId;
  final MemNotificationType type;
  final int? time;
  final String message;

  MemNotificationV2(this.memId, this.type, this.time, this.message);

  factory MemNotificationV2.fromV1(MemNotification v1) => MemNotificationV2(
        v1.memId as int,
        v1.type,
        v1.time,
        v1.message,
      );
}

class SavedMemNotificationV2<I> extends MemNotificationV2
    with SavedDatabaseTuple<I> {
  SavedMemNotificationV2(super.memId, super.type, super.time, super.message);

  MemNotification toV1() => MemNotification(
        type,
        time,
        message,
        memId: memId,
        id: id as int,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archivedAt: archivedAt,
      );

  factory SavedMemNotificationV2.fromV1(MemNotification v1) =>
      SavedMemNotificationV2(
        v1.memId as int,
        v1.type,
        v1.time,
        v1.message,
      )
        ..id = v1.id as I
        ..createdAt = v1.createdAt as DateTime
        ..updatedAt = v1.updatedAt
        ..archivedAt = v1.archivedAt;
}

class MemNotification extends EntityValue {
  int? memId;
  final MemNotificationType type;
  final int? time;
  final String message;

  MemNotification(
    this.type,
    this.time,
    this.message, {
    this.memId,
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  MemNotification copyWith(int? time, String message) => MemNotification(
        type,
        time,
        message,
        memId: memId,
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archivedAt: archivedAt,
      );

  @override
  String toString() =>
      {
        'memId': memId,
        'type': type,
        'time': time,
        'message': message,
      }.toString() +
      super.toString();
}

enum MemNotificationType {
  repeat,
  afterActStarted;

  factory MemNotificationType.fromName(String name) {
    if (name == MemNotificationType.repeat.name) {
      return MemNotificationType.repeat;
    } else if (name == MemNotificationType.afterActStarted.name) {
      return MemNotificationType.afterActStarted;
    }

    throw Exception('Unexpected name: "$name".');
  }
}
