import 'package:drift/drift.dart';

mixin BaseColumns on Table {
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
