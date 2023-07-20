import 'package:mem/database/table_definitions/acts.dart';
import 'package:mem/database/table_definitions/mem_items.dart';
import 'package:mem/database/table_definitions/mem_notifications.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/database_definition.dart';

final databaseDefinition = DatabaseDefinition(
  'mem.db',
  7,
  [
    memTableDefinition,
    memItemTableDefinition,
    actTableDefinition,
    memNotificationTableDefinition,
  ],
);
