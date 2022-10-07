import 'package:mem/database/definitions.dart';

const tableName = 'tests';
const pkName = 'id';
const textFieldName = 'text';
const datetimeFieldName = 'datetime';
final testTable = DefT(
  tableName,
  [
    DefPK(pkName, TypeC.integer, autoincrement: true),
    DefC(textFieldName, TypeC.integer),
    DefC(datetimeFieldName, TypeC.datetime),
  ],
);
final testChildTable = DefT(
  'test_children',
  [
    DefPK(pkName, TypeC.integer, autoincrement: true),
    ForeignKeyDefinition(testTable),
  ],
);

const dbName = 'test.db';
const dbVersion = 1;
final defD = DefD(
  dbName,
  dbVersion,
  [
    testTable,
    testChildTable,
  ],
);

final addingTableDefinition = DefT(
  'added_table',
  [
    DefPK('id', TypeC.integer, autoincrement: true),
    DefC('test', TypeC.text),
  ],
);

final upgradingByAddTableDefD = DefD(
  defD.name,
  2,
  [
    ...defD.tableDefinitions,
    addingTableDefinition,
  ],
);

final upgradingByAddColumnDefD = DefD(
  defD.name,
  2,
  [
    DefT(
      testTable.name,
      [
        ...testTable.columns,
        DefC('adding_column', TypeC.datetime, notNull: false),
      ],
    ),
    testChildTable,
  ],
);
