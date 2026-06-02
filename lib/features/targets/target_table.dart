import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';

class Targets extends Table with BaseColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get unit => text()();
  IntColumn get value => integer()();
  TextColumn get period => text()();
  IntColumn get memId => integer().references(Mems, #id)();
}
