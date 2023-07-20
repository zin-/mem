import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column_definition.dart';
import 'package:mem/framework/database/definition/column_type.dart';
import 'package:mem/framework/database/definition/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final memIdFkDef = ForeignKeyDefinition(memTableDefinition);
final timeColDef = ColumnDefinition(
  // ISSUE #230 change name to "time"
  'time_of_day_seconds',
  ColumnType.integer,
);

final memNotificationTableDefinition = TableDefinition(
  // ISSUE #230 change name to "mem_notifications"
  'mem_repeated_notifications',
  [
    timeColDef,
    ...defaultColumnDefinitions,
    memIdFkDef,
  ],
);
