import 'package:mem/database/table_definitions/mem_repeated_notifications.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';

class MemRepeatedNotificationEntity extends DatabaseTupleEntity {
  final int memId;
  final int timeOfDaySeconds;

  MemRepeatedNotificationEntity(
    this.memId,
    this.timeOfDaySeconds,
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  ) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  MemRepeatedNotificationEntity.fromMap(Map<String, dynamic> valueMap)
      : memId = valueMap[memIdFkDef.name],
        timeOfDaySeconds = valueMap[timeOfDaySecondsColDef.name],
        super.fromMap(valueMap);

  @override
  Map<String, dynamic> toMap() => {
        memIdFkDef.name: memId,
        timeOfDaySecondsColDef.name: timeOfDaySeconds,
      }..addAll(super.toMap());
}
