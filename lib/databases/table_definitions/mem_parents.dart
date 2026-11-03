import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';

class MemParents extends Table with BaseColumns {
  IntColumn get id => integer().autoIncrement()();

  @ReferenceName('childMem')
  IntColumn get memId => integer().unique().references(Mems, #id)();

  @ReferenceName('parentMem')
  IntColumn get parentMemId => integer().references(Mems, #id)();
}
