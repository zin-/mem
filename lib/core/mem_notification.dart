import 'package:mem/core/date_and_time/time_of_day.dart';
import 'package:mem/core/entity_value.dart';

class MemNotification extends EntityValue {
  int? memId;
  final MemNotificationType type;
  final TimeOfDay? timeOfDay;
  final String message;

  MemNotification(
    this.type,
    this.timeOfDay,
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

  @override
  String toString() =>
      {
        'memId': memId,
        'type': type,
        'timeOfDay': timeOfDay,
        'message': message,
      }.toString() +
      super.toString();
}

enum MemNotificationType {
  repeat;

  factory MemNotificationType.fromName(String name) {
    if (name == MemNotificationType.repeat.name) {
      return MemNotificationType.repeat;
    }
    throw Exception('Unexpected name: "$name".');
  }
}
