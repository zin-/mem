import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';

class Acts extends Table with BaseColumns {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get start => dateTime().nullable()();
  BoolColumn get startIsAllDay => boolean().nullable()();
  DateTimeColumn get end => dateTime().nullable()();
  BoolColumn get endIsAllDay => boolean().nullable()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  TextColumn get actKind => text().nullable()();
  IntColumn get memId => integer().references(Mems, #id)();
}
