import 'package:mem/framework/database/column_definition.dart';
import 'package:mem/framework/database/table_definition.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';

final defActId =
    PrimaryKeyDefinition(idColumnName, ColumnType.integer, autoincrement: true);
final defActStart = ColumnDefinition('start', ColumnType.datetime);
final defActStartIsAllDay =
    ColumnDefinition('start_is_all_day', ColumnType.integer);
final defActEnd = ColumnDefinition('end', ColumnType.datetime, notNull: false);
final defActEndIsAllDay =
    ColumnDefinition('end_is_all_day', ColumnType.integer, notNull: false);
final fkDefMemId = ForeignKeyDefinition(memTableDefinition);

final actTableDefinition = TableDefinition(
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
