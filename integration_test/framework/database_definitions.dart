import 'package:mem/framework/database/definition/column/boolean_column_definition.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/column/timestamp_column_definition.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final sampleDefPk = IntegerColumnDefinition(
  'sample_pk_integer',
  isPrimaryKey: true,
);
final sampleDefColInteger = IntegerColumnDefinition('sample_integer');
final sampleDefColText = TextColumnDefinition('sample_text');
final sampleDefColTimeStamp = TimestampColumnDefinition('sample_timestamp');
final sampleDefColBoolean = BooleanColumnDefinition('sample_boolean');
final sampleDefTable = TableDefinitionV2(
  'sample_table',
  [
    sampleDefPk,
    sampleDefColInteger,
    sampleDefColText,
    sampleDefColTimeStamp,
    sampleDefColBoolean,
  ],
  singularName: 'sample_table_singular_name',
);
final sampleDefPkChild = IntegerColumnDefinition(
  'sample_pk_child',
  isPrimaryKey: true,
);
final sampleDefFkChild = ForeignKeyDefinition(sampleDefTable);

final sampleDefTableChild = TableDefinitionV2(
  'sample_child_table',
  [
    sampleDefPkChild,
    sampleDefFkChild,
  ],
);
final sampleDefDb = DatabaseDefinitionV2(
  'sample_database.db',
  1,
  [
    sampleDefTable,
    sampleDefTableChild,
  ],
);

final sampleDefTableAdded = TableDefinitionV2(
  'added_table',
  [
    IntegerColumnDefinition('test_integer'),
  ],
);
final sampleDefDBAddedTable = DatabaseDefinitionV2(
  sampleDefDb.name,
  sampleDefDb.version + 1,
  [
    ...sampleDefDb.tableDefinitions,
    sampleDefTableAdded,
  ],
);

final sampleDefTableChildAddedColumn = TableDefinitionV2(
  sampleDefTableChild.name,
  [
    ...sampleDefTableChild.columnDefinitions,
    IntegerColumnDefinition(
      'test_integer',
      // FIXME Nullableで定義しないとデータ移行が行なえない
      // ISSUE #230
      notNull: false,
    )
  ],
);
final sampleDefDBAddedColumn = DatabaseDefinitionV2(
  sampleDefDBAddedTable.name,
  sampleDefDBAddedTable.version + 1,
  sampleDefDBAddedTable.tableDefinitions.toList(growable: true)
    ..removeWhere(
        (element) => element.name == sampleDefTableChildAddedColumn.name)
    ..add(sampleDefTableChildAddedColumn),
);
