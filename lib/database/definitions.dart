import 'package:mem/acts/act_entity.dart';
import 'package:mem/framework/database/definition.dart';
import 'package:mem/repositories/mem_entity.dart';
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
