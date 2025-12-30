import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final defFkMemRelationsSourceMemId =
    ForeignKeyDefinition(defTableMems, prefix: "source");
final defFkMemRelationsTargetMemId =
    ForeignKeyDefinition(defTableMems, prefix: "target");
final defColMemRelationsType = TextColumnDefinition('type');
final defColMemRelationsValue =
    IntegerColumnDefinition('value', notNull: false);

final defTableMemRelations = TableDefinition(
  "mem_relations",
  [
    defFkMemRelationsSourceMemId,
    defFkMemRelationsTargetMemId,
    defColMemRelationsType,
    defColMemRelationsValue,
    ...defColsBase,
  ],
);

class MemRelations extends Table with BaseColumns {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('sourceMem')
  IntColumn get sourceMemId => integer().references(Mems, #id)();
  @ReferenceName('targetMem')
  IntColumn get targetMemId => integer().references(Mems, #id)();
  TextColumn get type => text()();
  IntColumn get value => integer().nullable()();
}
