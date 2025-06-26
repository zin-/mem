import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final defColMemRelationsSourceMemId =
    ForeignKeyDefinition(defTableMems, prefix: "source");
final defColMemRelationsTargetMemId =
    ForeignKeyDefinition(defTableMems, prefix: "target");
final defColMemRelationsType = TextColumnDefinition('type');

final defTableMemRelations = TableDefinition(
  "mem_relations",
  [
    defColMemRelationsSourceMemId,
    defColMemRelationsTargetMemId,
    defColMemRelationsType,
    ...defColsBase,
  ],
);
