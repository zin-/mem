import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/column_definition.dart';
import 'package:mem/framework/database/table_definition.dart';

final memItemTypeColDef = ColumnDefinition('type', ColumnType.text);
final memItemValueColDef = ColumnDefinition('value', ColumnType.text);
final memIdFkDef = ForeignKeyDefinition(memTableDefinition);

final memItemTableDefinition = TableDefinition(
  'mem_items',
  [
    memItemTypeColDef,
    memItemValueColDef,
    ...defaultColumnDefinitions,
    ForeignKeyDefinition(memTableDefinition),
  ],
);
