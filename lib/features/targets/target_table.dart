import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

const _tableName = "targets";

final defFkTargetMemId = ForeignKeyDefinition(defTableMems);
final defColTargetType = TextColumnDefinition('type');
final defColTargetUnit = TextColumnDefinition('unit');
final defColTargetValue = IntegerColumnDefinition('value');
final defColTargetPeriod = TextColumnDefinition('period');

final defTableTargets = TableDefinition(
  _tableName,
  [
    defColTargetType,
    defColTargetUnit,
    defColTargetValue,
    defColTargetPeriod,
    ...defColsBase,
    defFkTargetMemId,
  ],
);
