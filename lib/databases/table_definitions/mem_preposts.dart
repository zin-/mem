import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';

class MemPrePosts extends Table with BaseColumns {
  IntColumn get id => integer().autoIncrement()();

  @ReferenceName('sourceMem')
  IntColumn get sourceMemId => integer().references(Mems, #id)();

  @ReferenceName('targetMem')
  IntColumn get targetMemId => integer().references(Mems, #id)();

  IntColumn get minutes => integer().nullable()();

  @override
  String get tableName => 'mem_preposts';
}
