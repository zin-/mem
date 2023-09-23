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
final sampleDefTable = TableDefinition(
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

final sampleDefTableChild = TableDefinition(
  'sample_child_table',
  [
    sampleDefPkChild,
    sampleDefFkChild,
  ],
);
final sampleDefDb = DatabaseDefinition(
  'sample_database.db',
  1,
  [
    sampleDefTable,
    sampleDefTableChild,
  ],
);

final sampleDefTableAdded = TableDefinition(
  'added_table',
  [
    IntegerColumnDefinition('test_integer'),
  ],
);
final sampleDefDBAddedTable = DatabaseDefinition(
  sampleDefDb.name,
  sampleDefDb.version + 1,
  [
    ...sampleDefDb.tableDefinitions,
    sampleDefTableAdded,
  ],
);

final sampleDefTableChildAddedColumn = TableDefinition(
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
final sampleDefDBAddedColumn = DatabaseDefinition(
  sampleDefDBAddedTable.name,
  sampleDefDBAddedTable.version + 1,
  sampleDefDBAddedTable.tableDefinitions.toList(growable: true)
    ..removeWhere(
        (element) => element.name == sampleDefTableChildAddedColumn.name)
    ..add(sampleDefTableChildAddedColumn),
);
