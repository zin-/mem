import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/column/timestamp_column_definition.dart';
import 'package:mem/framework/database/definition/database_definition_v2.dart';
import 'package:mem/framework/database/definition/table_definition_v2.dart';

final testDefInteger = IntegerColumnDefinition('test_integer');
final testDefText = TextColumnDefinition('test_text');
final testTableDefinition = TableDefinitionV2(
  'test_table',
  [
    testDefInteger,
    testDefText,
    IntegerColumnDefinition(
      'test_pk_integer',
      isPrimaryKey: true,
    ),
  ],
  singularName: 'test_table_singular_name',
);
final testDefFk = ForeignKeyDefinition(testTableDefinition);
final testDefTimeStamp = TimestampColumnDefinition('test_timestamp');
final testChildTableDefinition = TableDefinitionV2(
  'test_child_table',
  [
    testDefFk,
    testDefTimeStamp,
  ],
);
final testDatabaseDefinition = DatabaseDefinitionV2(
  'sample_database.db',
  1,
  [
    testTableDefinition,
    testChildTableDefinition,
  ],
);

final testAddedTableDefinition = TableDefinitionV2(
  'added_table',
  [
    IntegerColumnDefinition('test_integer'),
  ],
);
final testDatabaseDefinitionAddedTable = DatabaseDefinitionV2(
  testDatabaseDefinition.name,
  testDatabaseDefinition.version + 1,
  [
    ...testDatabaseDefinition.tableDefinitions,
    testAddedTableDefinition,
  ],
);

final testAddedColumnChildTableDefinition = TableDefinitionV2(
  testChildTableDefinition.name,
  testChildTableDefinition.columnDefinitions.toList(growable: true)
    ..add(IntegerColumnDefinition(
      'test_integer',
      // FIXME Nullableで定義しないとデータ移行が行なえない
      // ISSUE #230
      notNull: false,
    )),
);
final testDatabaseDefinitionAddedColumn = DatabaseDefinitionV2(
  testDatabaseDefinitionAddedTable.name,
  testDatabaseDefinitionAddedTable.version + 1,
  [
    testTableDefinition,
    testAddedColumnChildTableDefinition,
    testAddedTableDefinition,
  ],
);
