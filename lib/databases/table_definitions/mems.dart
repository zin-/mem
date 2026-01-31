import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart' as drift_database;
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/database/definition/column/text_column_definition.dart';
import 'package:mem/framework/database/definition/column/timestamp_column_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';

const _tableName = "mems";

final defColMemsName = TextColumnDefinition('name');
final defColMemsDoneAt = TimestampColumnDefinition('doneAt', notNull: false);
final defColMemsStartOn = TimestampColumnDefinition('notifyOn', notNull: false);
final defColMemsStartAt = TimestampColumnDefinition('notifyAt', notNull: false);
final defColMemsEndOn = TimestampColumnDefinition('endOn', notNull: false);
final defColMemsEndAt = TimestampColumnDefinition('endAt', notNull: false);

final defTableMems = TableDefinition(
  _tableName,
  [
    defColMemsName,
    defColMemsDoneAt,
    defColMemsStartOn,
    defColMemsStartAt,
    defColMemsEndOn,
    defColMemsEndAt,
    ...defColsBase
  ],
  singularName: "mem",
);

class Mems extends Table with BaseColumns {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get doneAt => dateTime().nullable()();
  DateTimeColumn get notifyOn => dateTime().nullable()();
  DateTimeColumn get notifyAt => dateTime().nullable()();
  DateTimeColumn get endOn => dateTime().nullable()();
  DateTimeColumn get endAt => dateTime().nullable()();
}

convertIntoMemsInsertable(Mem domain, DateTime createdAt) =>
    drift_database.MemsCompanion.insert(
      name: domain.name,
      doneAt: Value(domain.doneAt),
      notifyOn: Value(domain.period?.start),
      notifyAt: Value(
          domain.period?.start?.isAllDay == true ? null : domain.period?.start),
      endOn: Value(domain.period?.end),
      endAt: Value(
          domain.period?.end?.isAllDay == true ? null : domain.period?.end),
      createdAt: createdAt,
    );
