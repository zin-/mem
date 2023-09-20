import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final defColMemItemsType = TextColumnDefinition('type');
final defColMemItemsValue = TextColumnDefinition('value');
final defFkMemItemsMemId = ForeignKeyDefinition(defTableMems);

final defTableMemItems = TableDefinition(
  'mem_items',
  [
    defColMemItemsType,
    defColMemItemsValue,
    defFkMemItemsMemId,
    ...defColsBase,
  ],
);
