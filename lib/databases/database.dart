import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mem/databases/migrations/native_to_drift.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:path_provider/path_provider.dart';
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

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        await migrateNativeToDrift(this);
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
