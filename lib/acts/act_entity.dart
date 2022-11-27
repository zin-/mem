import 'package:mem/database/i/types.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';
import 'package:mem/repositories/mem_repository.dart';

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

class ActEntity extends DatabaseTupleEntityV2 {
  ActEntity({required super.id});
}
