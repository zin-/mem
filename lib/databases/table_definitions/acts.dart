import 'package:drift/drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/definition/column/boolean_column_definition.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/definition/column/timestamp_column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

const _tableName = "acts";

final defColActsStart = TimestampColumnDefinition('start', notNull: false);
final defColActsStartIsAllDay =
    BooleanColumnDefinition('start_is_all_day', notNull: false);
final defColActsEnd = TimestampColumnDefinition('end', notNull: false);
final defColActsEndIsAllDay =
    BooleanColumnDefinition('end_is_all_day', notNull: false);
final defColActsPausedAt =
    TimestampColumnDefinition('paused_at', notNull: false);
final defFkActsMemId = ForeignKeyDefinition(defTableMems);

final defTableActs = TableDefinition(
  _tableName,
  [
    defColActsStart,
    defColActsStartIsAllDay,
    defColActsEnd,
    defColActsEndIsAllDay,
    defColActsPausedAt,
    ...defColsBase,
    defFkActsMemId,
  ],
);

class Acts extends Table with BaseColumns {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get start => dateTime().nullable()();
  BoolColumn get startIsAllDay => boolean().nullable()();
  DateTimeColumn get end => dateTime().nullable()();
  BoolColumn get endIsAllDay => boolean().nullable()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  IntColumn get memId => integer().references(Mems, #id)();
}
