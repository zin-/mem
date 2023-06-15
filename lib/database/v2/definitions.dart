import 'package:mem/acts/act_entity.dart';
import 'package:mem/database/i/types.dart';
import 'package:mem/repositories/mem_entity.dart';
import 'package:mem/repositories/mem_item_repository.dart';

final databaseDefinition = DefD(
  'mem.db',
  5,
  [
    memTableDefinition,
    memItemTableDefinition,
    actTableDefinition,
  ],
);
