import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mem/databases/database_file_name.dart';
import 'package:path/path.dart' as path;

part 'database.g.dart';

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

  /// 永続ファイルを使わない SQLite。単体テストで本番 DB と干渉しないようにするため。
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(acts, acts.actKind);
          await backfillFinishedActKind(this);
        }
      },
    );
  }
}

Future<void> backfillFinishedActKind(AppDatabase db) => (db.update(db.acts)
      ..where(
        (row) => row.start.isNotNull() & row.end.isNotNull(),
      ))
    .write(
      ActsCompanion(actKind: Value(ActKind.finished.name)),
    );

bool _onTest = false;

void setOnTest(bool value) {
  _onTest = value;
}

Future<String> getDatabaseFilePath() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbName = _onTest ? testDatabaseFileName : databaseFileName;
  return path.join(dbFolder.path, dbName);
}

Future<File?> getDatabaseFile() async {
  final p = await getDatabaseFilePath();
  final f = File(p);
  return (await f.exists()) ? f : null;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final p = await getDatabaseFilePath();
    return NativeDatabase(File(p));
  });
}
