import 'package:mem/core/mem.dart';
import 'package:mem/database/i/types.dart';
import 'package:mem/repositories/mem_entity.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';
import 'package:mem/repositories/i/types.dart';

final defActId = DefPK(idColumnName, TypeC.integer, autoincrement: true);
final defActStart = DefC('start', TypeC.datetime);
final defActStartIsAllDay = DefC('start_is_all_day', TypeC.integer);
final defActEnd = DefC('end', TypeC.datetime, notNull: false);
final defActEndIsAllDay = DefC('end_is_all_day', TypeC.integer, notNull: false);
final fkDefMemId = DefFK(memTableDefinition);

final actTableDefinition = DefT(
  'acts',
  [
    defActId,
    defActStart,
    defActStartIsAllDay,
    defActEnd,
    defActEndIsAllDay,
    ...defaultColumnDefinitions,
    fkDefMemId,
  ],
);

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
