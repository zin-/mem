import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column/column_definition.dart';
import 'package:mem/framework/database/definition/column/column_type.dart';
import 'package:mem/framework/database/definition/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

final defFkMemNotificationsMemId = ForeignKeyDefinition(defTableMems);
final defColMemNotificationsTime = ColumnDefinition(
  // ISSUE #230 change name to "time"
  'time_of_day_seconds',
  ColumnType.integer,
);
final defColMemNotificationsType = ColumnDefinition(
  'type',
  ColumnType.text,
  // ISSUE #230 remove
  //  本来はmigration定義に含まれるべきだが、実装していないのでこれで対応している
  defaultValue: 'repeat',
);
final defColMemNotificationsMessage = ColumnDefinition(
  'message',
  ColumnType.text,
  // ISSUE #230 remove
  //  本来はmigration定義に含まれるべきだが、実装していないのでこれで対応している
  defaultValue: 'Repeat',
);

final defTableMemNotifications = TableDefinition(
  // ISSUE #230 change name to "mem_notifications"
  'mem_repeated_notifications',
  [
    defColMemNotificationsTime,
    defColMemNotificationsType,
    defColMemNotificationsMessage,
    ...defColsBase,
    defFkMemNotificationsMemId,
  ],
);
