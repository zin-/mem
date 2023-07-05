import 'package:mem/core/date_and_time/time_of_day.dart';
import 'package:mem/core/entity_value.dart';

class MemRepeatedNotification extends EntityValue {
  int? memId;
  final TimeOfDay timeOfDay;

  MemRepeatedNotification(
    this.timeOfDay, {
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
  String toString() => {
        'memId': memId,
        'timeOfDay': timeOfDay,
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      }.toString();
}
