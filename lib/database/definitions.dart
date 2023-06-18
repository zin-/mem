import 'package:mem/database/tables/acts.dart';
import 'package:mem/database/tables/mems.dart';
import 'package:mem/framework/database/definition.dart';
import 'package:mem/repositories/mem_item_repository.dart';

final databaseDefinition = DatabaseDefinition(
  'mem.db',
  5,
  [
    memTableDefinition,
    memItemTableDefinition,
    actTableDefinition,
  ],
);
