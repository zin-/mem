import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/definition/column/column_definition.dart';
import 'package:mem/framework/database/definition/column/column_type.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final defColMemsName = ColumnDefinition('name', ColumnType.text);
final defColMemsDoneAt =
    ColumnDefinition('doneAt', ColumnType.datetime, notNull: false);
final defColMemsStartOn =
    ColumnDefinition('notifyOn', ColumnType.datetime, notNull: false);
final defColMemsStartAt =
    ColumnDefinition('notifyAt', ColumnType.datetime, notNull: false);
final defColMemsEndOn =
    ColumnDefinition('endOn', ColumnType.datetime, notNull: false);
final defColMemsEndAt =
    ColumnDefinition('endAt', ColumnType.datetime, notNull: false);

final defTableMems = TableDefinition(
  'mems',
  [
    defColMemsName,
    defColMemsDoneAt,
    defColMemsStartOn,
    defColMemsStartAt,
    defColMemsEndOn,
    defColMemsEndAt,
    ...defColsBase
  ],
);
