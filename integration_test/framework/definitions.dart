import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/column/timestamp_column_definition.dart';
import 'package:mem/framework/database/definition/database_definition_v2.dart';
import 'package:mem/framework/database/definition/table_definition_v2.dart';

final sampleDefColInteger = IntegerColumnDefinition('sample_integer');
final sampleDefColText = TextColumnDefinition('sample_text');
final sampleDefPk = IntegerColumnDefinition(
  'sample_pk_integer',
  isPrimaryKey: true,
);
final sampleDefTable = TableDefinitionV2(
  'sample_table',
  [
    sampleDefColInteger,
    sampleDefColText,
    sampleDefPk,
  ],
  singularName: 'sample_table_singular_name',
);

final sampleDefFk = ForeignKeyDefinition(sampleDefTable);
final sampleDefColTimeStamp = TimestampColumnDefinition('sample_timestamp');
final sampleDefTableChild = TableDefinitionV2(
  'sample_child_table',
  [
    sampleDefFk,
    sampleDefColTimeStamp,
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
  sampleDefTableChild.columnDefinitions.toList(growable: true)
    ..add(IntegerColumnDefinition(
      'test_integer',
      // FIXME Nullableで定義しないとデータ移行が行なえない
      // ISSUE #230
      notNull: false,
    )),
);
final sampleDefDBAddedColumn = DatabaseDefinitionV2(
  sampleDefDBAddedTable.name,
  sampleDefDBAddedTable.version + 1,
  [
    sampleDefTable,
    sampleDefTableChildAddedColumn,
    sampleDefTableAdded,
  ],
);
