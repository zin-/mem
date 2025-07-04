import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final defFkMemRelationsSourceMemId =
    ForeignKeyDefinition(defTableMems, prefix: "source");
final defFkMemRelationsTargetMemId =
    ForeignKeyDefinition(defTableMems, prefix: "target");
final defColMemRelationsType = TextColumnDefinition('type');

final defTableMemRelations = TableDefinition(
  "mem_relations",
  [
    defFkMemRelationsSourceMemId,
    defFkMemRelationsTargetMemId,
    defColMemRelationsType,
    ...defColsBase,
  ],
);
