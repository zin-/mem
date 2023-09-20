import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column_definition.dart';
import 'package:mem/framework/database/definition/column_type.dart';
import 'package:mem/framework/database/definition/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final defColActsStart = ColumnDefinition('start', ColumnType.datetime);
final defColActsStartIsAllDay =
    ColumnDefinition('start_is_all_day', ColumnType.integer);
final defColActsEnd = ColumnDefinition('end', ColumnType.datetime, notNull: false);
final defColActsEndIsAllDay =
    ColumnDefinition('end_is_all_day', ColumnType.integer, notNull: false);
final defFkActsMemId = ForeignKeyDefinition(defTableMems);

final defTableActs = TableDefinition(
  'acts',
  [
    defColActsStart,
    defColActsStartIsAllDay,
    defColActsEnd,
    defColActsEndIsAllDay,
    ...defColsBase,
    defFkActsMemId,
  ],
);
