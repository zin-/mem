import 'package:mem/database/i/types.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';

const memIdColumnName = 'mems_id';
const memItemTypeColumnName = 'type';
const memItemValueColumnName = 'value';

final memItemTableDefinition = DefT(
  'mem_items',
  [
    DefPK(idColumnName, TypeC.integer, autoincrement: true),
    DefC(memItemTypeColumnName, TypeC.text),
    DefC(memItemValueColumnName, TypeC.text),
    ...defaultColumnDefinitions,
    DefFK(memTableDefinition),
  ],
);
