import 'package:mem/core/entity_value.dart';

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
