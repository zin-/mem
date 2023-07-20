import 'package:mem/database/table_definitions/mem_notifications.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';

class MemNotificationEntity extends DatabaseTupleEntity {
  final int memId;
  final int time;

  MemNotificationEntity(
    this.memId,
    this.time,
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

  MemNotificationEntity.fromMap(Map<String, dynamic> valueMap)
      : memId = valueMap[memIdFkDef.name],
        time = valueMap[timeColDef.name],
        super.fromMap(valueMap);

  @override
  Map<String, dynamic> toMap() => {
        memIdFkDef.name: memId,
        timeColDef.name: time,
      }..addAll(super.toMap());
}
