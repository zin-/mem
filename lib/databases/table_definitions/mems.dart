import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/column/timestamp_column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

const _tableName = "mems";

final defColMemsName = TextColumnDefinition('name');
final defColMemsDoneAt = TimestampColumnDefinition('doneAt', notNull: false);
final defColMemsStartOn = TimestampColumnDefinition('notifyOn', notNull: false);
final defColMemsStartAt = TimestampColumnDefinition('notifyAt', notNull: false);
final defColMemsEndOn = TimestampColumnDefinition('endOn', notNull: false);
final defColMemsEndAt = TimestampColumnDefinition('endAt', notNull: false);

final defTableMems = TableDefinition(
  _tableName,
  [
    defColMemsName,
    defColMemsDoneAt,
    defColMemsStartOn,
    defColMemsStartAt,
    defColMemsEndOn,
    defColMemsEndAt,
    ...defColsBase
  ],
  singularName: "mem",
);
