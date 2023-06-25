import 'package:mem/core/mem.dart';
import 'package:mem/database/table_definitions/acts.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';
import 'package:mem/repositories/i/types.dart';

class ActEntity extends DatabaseTupleEntity {
  final MemId memId;
  final DateTime start;
  final bool startIsAllDay;
  final DateTime? end;
  final bool? endIsAllDay;

  ActEntity(
    this.memId,
    this.start,
    this.startIsAllDay,
    this.end,
    this.endIsAllDay,
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

  ActEntity.fromMap(Map<String, dynamic> valueMap)
      : memId = valueMap[fkDefMemId.name],
        start = valueMap[defActStart.name],
        startIsAllDay = valueMap[defActStartIsAllDay.name] == 1,
        end = valueMap[defActEnd.name],
        endIsAllDay = valueMap[defActEndIsAllDay.name] == null
            ? null
            : valueMap[defActEndIsAllDay.name] == 1,
        super.fromMap(valueMap);

  @override
  Map<AttributeName, dynamic> toMap() => {
        fkDefMemId.name: memId,
        defActStart.name: start,
        defActStartIsAllDay.name: startIsAllDay ? 1 : 0,
        defActEnd.name: end,
        defActEndIsAllDay.name: endIsAllDay ?? false ? 1 : 0,
      }..addAll(super.toMap());
}
