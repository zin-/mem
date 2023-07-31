import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/column/timestamp_column_definition.dart';
import 'package:mem/framework/database/definition/database_definition_v2.dart';
import 'package:mem/framework/database/definition/table_definition_v2.dart';

final testTableDefinition = TableDefinitionV2(
  'test_table',
  [
    IntegerColumnDefinition('test_integer'),
    TextColumnDefinition('test_text'),
    IntegerColumnDefinition(
      'test_pk_integer',
      isPrimaryKey: true,
    ),
  ],
  singularName: 'test_table_singular_name',
);

final testChildTableDefinition = TableDefinitionV2(
  'test_child_table',
  [
    ForeignKeyDefinition(testTableDefinition),
    TimestampColumnDefinition('test_timestamp'),
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
