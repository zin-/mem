import 'package:mem/database/tables/mems.dart';
import 'package:mem/framework/database/column_definition.dart';
import 'package:mem/framework/database/table_definition.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';

const memIdColumnName = 'mems_id';
const memItemTypeColumnName = 'type';
const memItemValueColumnName = 'value';

final memItemTableDefinition = TableDefinition(
  'mem_items',
  [
    PrimaryKeyDefinition(idColumnName, ColumnType.integer, autoincrement: true),
    ColumnDefinition(memItemTypeColumnName, ColumnType.text),
    ColumnDefinition(memItemValueColumnName, ColumnType.text),
    ...defaultColumnDefinitions,
    ForeignKeyDefinition(memTableDefinition),
  ],
);
