import 'package:mem/database/tables/mems.dart';
import 'package:mem/framework/database/types.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';

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
