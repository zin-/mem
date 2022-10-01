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
final defD = DefD(
  'test.db',
  1,
  [
    testTable,
    testChildTable,
  ],
);
