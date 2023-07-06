import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column_definition.dart';
import 'package:mem/framework/database/definition/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

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
