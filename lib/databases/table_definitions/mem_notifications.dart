import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/integer_column_definition.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

// ISSUE #230 change name to "mem_notifications"
const _tableName = "mem_repeated_notifications";

final defFkMemNotificationsMemId = ForeignKeyDefinition(defTableMems);
final defColMemNotificationsTime = IntegerColumnDefinition(
  // ISSUE #230 change name to "time"
  'time_of_day_seconds',
);
final defColMemNotificationsType = TextColumnDefinition('type');
final defColMemNotificationsMessage = TextColumnDefinition('message');

final defTableMemNotifications = TableDefinition(
  // ISSUE #230 change name to "mem_notifications"
  _tableName,
  [
    defColMemNotificationsTime,
    defColMemNotificationsType,
    defColMemNotificationsMessage,
    ...defColsBase,
    defFkMemNotificationsMemId,
  ],
);

class MemRepeatedNotifications extends Table with BaseColumns {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timeOfDaySeconds => integer()();
  TextColumn get type => text()();
  TextColumn get message => text()();
  IntColumn get memId => integer().references(Mems, #id)();
}
