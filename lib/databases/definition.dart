import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/database/definition/database_definition.dart';

final databaseDefinition = DatabaseDefinition(
  'mem.db',
  12,
  [
    defTableMems,
    defTableMemItems,
    defTableActs,
    defTableMemNotifications,
    defTableTargets,
    defTableMemRelations,
  ],
);
