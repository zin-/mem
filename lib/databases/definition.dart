import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/database_definition.dart';

const _dbName = 'mem.db';
const _dbVersion = 9;

final databaseDefinition = DatabaseDefinition(
  _dbName,
  _dbVersion,
  [
    defTableMems,
    defTableMemItems,
    defTableActs,
    defTableMemNotifications,
  ],
);
