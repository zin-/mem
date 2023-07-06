import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column_definition.dart';
import 'package:mem/framework/database/definition/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final memIdFkDef = ForeignKeyDefinition(memTableDefinition);
final timeOfDaySecondsColDef = ColumnDefinition(
  'time_of_day_seconds',
  ColumnType.integer,
);

final memRepeatedNotificationTableDefinition = TableDefinition(
  'mem_repeated_notifications',
  [
    timeOfDaySecondsColDef,
    ...defaultColumnDefinitions,
    memIdFkDef,
  ],
);
