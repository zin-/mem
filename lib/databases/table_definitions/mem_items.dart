import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column/column_definition.dart';
import 'package:mem/framework/database/definition/column/column_type.dart';
import 'package:mem/framework/database/definition/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final defColMemItemsType = ColumnDefinition('type', ColumnType.text);
final defColMemItemsValue = ColumnDefinition('value', ColumnType.text);
final defFkMemItemsMemId = ForeignKeyDefinition(defTableMems);

final defTableMemItems = TableDefinition(
  'mem_items',
  [
    defColMemItemsType,
    defColMemItemsValue,
    ...defColsBase,
    ForeignKeyDefinition(defTableMems),
  ],
);
