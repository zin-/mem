import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';

class MemRelations extends Table with BaseColumns {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('sourceMem')
  IntColumn get sourceMemId => integer().references(Mems, #id)();
  @ReferenceName('targetMem')
  IntColumn get targetMemId => integer().references(Mems, #id)();
  TextColumn get type => text()();
  IntColumn get value => integer().nullable()();
}
