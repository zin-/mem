import 'package:mem/core/mem.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/repositories/database_tuple_entity.dart';

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
      : memId = valueMap[defFkActsMemId.name],
        start = valueMap[defColActsStart.name],
        startIsAllDay = valueMap[defColActsStartIsAllDay.name] == 1,
        end = valueMap[defColActsEnd.name],
        endIsAllDay = valueMap[defColActsEndIsAllDay.name] == null
            ? null
            : valueMap[defColActsEndIsAllDay.name] == 1,
        super.fromMap(valueMap);

  @override
  Map<String, dynamic> toMap() => {
        defFkActsMemId.name: memId,
        defColActsStart.name: start,
        defColActsStartIsAllDay.name: startIsAllDay ? 1 : 0,
        defColActsEnd.name: end,
        defColActsEndIsAllDay.name: endIsAllDay ?? false ? 1 : 0,
      }..addAll(super.toMap());
}
