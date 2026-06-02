import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';

// ISSUE #230 change name to "mem_notifications"
class MemRepeatedNotifications extends Table with BaseColumns {
  IntColumn get id => integer().autoIncrement()();
  // ISSUE #230 change name to "time"
  IntColumn get timeOfDaySeconds => integer()();
  TextColumn get type => text()();
  TextColumn get message => text()();
  IntColumn get memId => integer().references(Mems, #id)();
}
