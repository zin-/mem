import 'package:mem/database/i/types.dart';
import 'package:mem/repositories/_database_tuple_entity_v2.dart';
import 'package:mem/repositories/mem_repository.dart';

final actId = DefPK(idColumnName, TypeC.integer, autoincrement: true);
final memId = DefFK(memTableDefinition);
final actStart = DefC('start', TypeC.datetime);
final actStartIsAllDay = DefC('start_is_all_day', TypeC.integer);
final actEnd = DefC('end', TypeC.datetime, notNull: false);
final actEndIsAllDay = DefC('end_is_all_day', TypeC.integer, notNull: false);

final actTableDefinition = DefT(
  'acts',
  [
    actId,
    actStart,
    actStartIsAllDay,
    actEnd,
    actEndIsAllDay,
    ...defaultColumnDefinitions,
    memId,
  ],
);
