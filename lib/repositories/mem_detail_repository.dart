import 'package:mem/database/definitions.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/repository.dart';

final memDetailTableDefinition = DefT(
  'mem_details',
  [
    DefPK(idColumnName, TypeC.integer, autoincrement: true),
    DefFK(memTableDefinition),
    ...defaultColumnDefinitions,
  ],
);

class MemDetailRepository {}
