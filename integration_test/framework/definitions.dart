import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/database_definition_v2.dart';
import 'package:mem/framework/database/definition/table_definition_v2.dart';

const testTableName = 'test_table';

final testTableDefinition = TableDefinitionV2(
  testTableName,
  [
    IntegerColumnDefinition('test_integer'),
    TextColumnDefinition('test_text'),
    IntegerColumnDefinition(
      'test_pk_integer',
      isPrimaryKey: true,
    ),
  ],
);

const testDatabaseName = 'test_database.db';
const testDatabaseVersion = 1;

final testDatabaseDefinition = DatabaseDefinitionV2(
  testDatabaseName,
  testDatabaseVersion,
  [
    testTableDefinition,
  ],
);
