import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

part 'database.g.dart';

class Mems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get doneAt => dateTime().nullable()();
  DateTimeColumn get notifyOn => dateTime().nullable()();
  DateTimeColumn get notifyAt => dateTime().nullable()();
  DateTimeColumn get endOn => dateTime().nullable()();
  DateTimeColumn get endAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class MemItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get value => text()();
  IntColumn get memId => integer().references(Mems, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class Acts extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get start => dateTime().nullable()();
  BoolColumn get startIsAllDay => boolean().nullable()();
  DateTimeColumn get end => dateTime().nullable()();
  BoolColumn get endIsAllDay => boolean().nullable()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  IntColumn get memId => integer().references(Mems, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class MemRepeatedNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timeOfDaySeconds => integer()();
  TextColumn get type => text()();
  TextColumn get message => text()();
  IntColumn get memId => integer().references(Mems, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class Targets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get unit => text()();
  IntColumn get value => integer()();
  TextColumn get period => text()();
  IntColumn get memId => integer().references(Mems, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class MemRelations extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('sourceMem')
  IntColumn get sourceMemId => integer().references(Mems, #id)();
  @ReferenceName('targetMem')
  IntColumn get targetMemId => integer().references(Mems, #id)();
  TextColumn get type => text()();
  IntColumn get value => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [
  Mems,
  MemItems,
  Acts,
  MemRepeatedNotifications,
  Targets,
  MemRelations,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // TODO: 独自実装からデータを移行する
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // TODO: マイグレーション処理を実装
      },
    );
  }
}

bool _onTest = false;

void setOnTest(bool value) {
  _onTest = value;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbName = _onTest ? 'test_mem_drift.db' : 'mem_drift.db';
    final file = File(path.join(dbFolder.path, dbName));
    return NativeDatabase(file);
  });
}
