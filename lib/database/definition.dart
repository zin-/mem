import 'package:mem/database/tables/acts.dart';
import 'package:mem/database/tables/mem_items.dart';
import 'package:mem/database/tables/mems.dart';
import 'package:mem/framework/database/definition.dart';

final databaseDefinition = DatabaseDefinition(
  'mem.db',
  5,
  [
    memTableDefinition,
    memItemTableDefinition,
    actTableDefinition,
  ],
);
