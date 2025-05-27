import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart' as sqflite_api;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;
import 'accessor.dart';
import 'definition/database_definition.dart';

const _testDatabasePrefix = "test_";

class DatabaseFactory {
  static var onTest = false;
  static final _nativeFactory = defaultTargetPlatform == TargetPlatform.windows
      ? () {
          sqflite.sqfliteFfiInit();
          return sqflite.databaseFactoryFfi;
        }()
      : sqflite.databaseFactory;

  @Deprecated("Use only for developing or test.")
  static sqflite.DatabaseFactory get nativeFactory => _nativeFactory;

  static Future<DatabaseAccessor> open(
    DatabaseDefinition databaseDefinition,
  ) =>
      i(
        () async => DatabaseAccessor(
          await _nativeFactory.openDatabase(
            await buildDatabasePath(databaseDefinition.name),
            options: sqflite.OpenDatabaseOptions(
              version: databaseDefinition.version,
              onConfigure: _onConfigure(databaseDefinition),
              onCreate: _onCreate(databaseDefinition),
              onUpgrade: _onUpgrade(databaseDefinition),
            ),
          ),
        ),
        databaseDefinition,
      );

  static Future<String> buildDatabasePath(
    String databaseName,
  ) async =>
      path.join(
        await _nativeFactory.getDatabasesPath(),
        "${onTest ? _testDatabasePrefix : ""}$databaseName",
      );

  static _onConfigure(DatabaseDefinition databaseDefinition) =>
      (sqflite_api.Database db) => i(
            () async {
              var foreignKeyIsEnabled = false;
              for (final tableDefinition
                  in databaseDefinition.tableDefinitions) {
                if (!foreignKeyIsEnabled &&
                    tableDefinition.foreignKeyDefinitions.isNotEmpty) {
                  const enableForeignKeysSql = "PRAGMA foreign_keys=true";

                  info("Enable foreign key :: \"$enableForeignKeysSql\".");
                  await db.execute(enableForeignKeysSql);

                  foreignKeyIsEnabled = true;
                }
              }
            },
            db,
          );

  static _onCreate(DatabaseDefinition databaseDefinition) =>
      (sqflite_api.Database db, int version) => i(
            () async {
              for (final tableDefinition
                  in databaseDefinition.tableDefinitions) {
                await _executeCreateTableSql(db, tableDefinition);
              }
            },
            [db, version],
          );

  static _onUpgrade(DatabaseDefinition databaseDefinition) =>
      (sqflite_api.Database db, int oldVersion, int newVersion) => i(
            () async {
              final oldTables = await _getCurrentTables(db);

              for (final newTableDefinition
                  in databaseDefinition.tableDefinitions) {
                final targetTableName = newTableDefinition.name;

                final oldTable = oldTables.singleWhereOrNull(
                  (table) => table["name"] == targetTableName,
                );

                if (oldTable == null) {
                  await _executeCreateTableSql(db, newTableDefinition);
                } else {
                  final newCreateTableSql =
                      newTableDefinition.buildCreateTableSql();

                  if (oldTable["sql"] == newCreateTableSql) {
                    verbose(
                      "Skip table \"${newTableDefinition.name}\", because sql is not changed.",
                    );
                  } else {
                    final tmpTableName = "tmp_$targetTableName";
                    final rows = await db.query(targetTableName);

                    final batch = db.batch();

                    final renameTableSql =
                        "ALTER TABLE $targetTableName RENAME TO $tmpTableName";
                    info("Rename table: \"$renameTableSql\".");
                    batch.execute(renameTableSql);

                    info("Create table: \"$newCreateTableSql\".");
                    batch.execute(newCreateTableSql);

                    for (final row in rows) {
                      batch.insert(targetTableName,
                          Map.fromEntries(row.entries.where(
                        (entry) {
                          return newTableDefinition.columnDefinitions
                              .map((e) => e.name)
                              .contains(entry.key);
                        },
                      )));
                    }

                    await batch.commit();
                  }
                }
              }

              final upgradedOrTmpTables =
                  await _getCurrentTables(db, asc: true);
              for (final upgradedOrTmpTable in upgradedOrTmpTables) {
                if (databaseDefinition.tableDefinitions
                    .where((tableDefinition) =>
                        tableDefinition.name == upgradedOrTmpTable["name"])
                    .isEmpty) {
                  final dropTableSql =
                      "DROP TABLE ${upgradedOrTmpTable['name']}";
                  info("Drop table: \"$dropTableSql\".");
                  await db.execute(dropTableSql);
                }
              }
            },
            [db, oldVersion, newVersion],
          );

  static Future<void> _executeCreateTableSql(
    sqflite.Database db,
    TableDefinition tableDefinition,
  ) async {
    final createTableSql = tableDefinition.buildCreateTableSql();
    info("Create table: \"$createTableSql\".");
    await db.execute(createTableSql);
  }

  static Future<List<Map<String, Object?>>> _getCurrentTables(
    sqflite.Database db, {
    bool asc = false,
  }) =>
      db.query(
        "sqlite_master",
        where: "NOT(name = ?) AND NOT(name = ?)",
        whereArgs: ["android_metadata", "sqlite_sequence"],
        orderBy: asc ? "rootpage ASC" : "rootpage DESC",
      );
}
