import 'package:mem/database/tables/base.dart';
import 'package:mem/database/tables/mems.dart';
import 'package:mem/framework/database/column_definition.dart';
import 'package:mem/framework/database/table_definition.dart';

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
    defActStart,
    defActStartIsAllDay,
    defActEnd,
    defActEndIsAllDay,
    ...defaultColumnDefinitions,
    fkDefMemId,
  ],
);
