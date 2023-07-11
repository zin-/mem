import 'package:mem/framework/database/definition/column_definition.dart';
import 'package:mem/framework/database/definition/column_type.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/primary_key_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

const tableName = 'tests';
const pkName = 'id';
const textFieldName = 'text';
const datetimeFieldName = 'datetime';
final testTable = TableDefinition(
  tableName,
  [
    PrimaryKeyDefinition(pkName, ColumnType.integer, autoincrement: true),
    ColumnDefinition(textFieldName, ColumnType.integer),
    ColumnDefinition(datetimeFieldName, ColumnType.datetime),
  ],
);
final testChildTable = TableDefinition(
  'test_children',
  [
    PrimaryKeyDefinition(pkName, ColumnType.integer, autoincrement: true),
    ForeignKeyDefinition(testTable),
  ],
);

const dbName = 'test.db';
const dbVersion = 1;
final defD = DatabaseDefinition(
  dbName,
  dbVersion,
  [
    testTable,
    testChildTable,
  ],
);

final addingTableDefinition = TableDefinition(
  'added_table',
  [
    PrimaryKeyDefinition('id', ColumnType.integer, autoincrement: true),
    ColumnDefinition('test', ColumnType.text),
  ],
);

final upgradingByAddTableDefD = DatabaseDefinition(
  defD.name,
  2,
  [
    ...defD.tableDefinitions,
    addingTableDefinition,
  ],
);

final upgradingByAddColumnDefD = DatabaseDefinition(
  defD.name,
  2,
  [
    TableDefinition(
      testTable.name,
      [
        ...testTable.columns,
        ColumnDefinition('adding_column', ColumnType.datetime, notNull: false),
      ],
    ),
    testChildTable,
  ],
);
