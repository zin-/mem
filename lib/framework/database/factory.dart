import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:mem/framework/database/definition/table_definition_v2.dart';
import 'package:mem/logger/log_service.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart' as sqflite_api;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;
import 'accessor.dart';
import 'definition/database_definition_v2.dart';

class DatabaseFactory {
  static final _nativeFactory = defaultTargetPlatform == TargetPlatform.windows
      ? () {
          sqflite.sqfliteFfiInit();
          return sqflite.databaseFactoryFfi;
        }()
      : sqflite.databaseFactory;

  @Deprecated("Use only for developing or test.")
  static sqflite.DatabaseFactory get nativeFactory => _nativeFactory;

  // FIXME Factoryに生成されたものがあるのは正しいのか？
  //  Factoryは生成するだけのクラスでなくてはならない
  //  -> Repositoryに移譲する
  static final _databaseAccessors = <String, DatabaseAccessor>{};

  // TODO add on test
  static Future<DatabaseAccessor> open(
    DatabaseDefinitionV2 databaseDefinition,
  ) =>
      i(
        () async {
          final contained = _databaseAccessors[databaseDefinition.name];

          if (await contained?.isOpened() ?? false) {
            return contained!;
          } else {
            final databaseAccessor = DatabaseAccessor(
              await _nativeFactory.openDatabase(
                await buildDatabasePath(databaseDefinition.name),
                options: sqflite.OpenDatabaseOptions(
                  version: databaseDefinition.version,
                  onConfigure: _onConfigure(databaseDefinition),
                  onCreate: _onCreate(databaseDefinition),
                  onUpgrade: _onUpgrade(databaseDefinition),
                ),
              ),
            );

            return _databaseAccessors.update(
              databaseDefinition.name,
              (value) => databaseAccessor,
              ifAbsent: () => databaseAccessor,
            );
          }
        },
        databaseDefinition,
      );

  static Future<String> buildDatabasePath(String databaseName) async =>
      path.join(
        await _nativeFactory.getDatabasesPath(),
        databaseName,
      );

  static _onConfigure(DatabaseDefinitionV2 databaseDefinition) =>
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

  static _onCreate(DatabaseDefinitionV2 databaseDefinition) =>
      (sqflite_api.Database db, int version) => i(
            () async {
              for (final tableDefinition
                  in databaseDefinition.tableDefinitions) {
                await _executeCreateTableSql(db, tableDefinition);
              }
            },
            [db, version],
          );

  static _onUpgrade(DatabaseDefinitionV2 databaseDefinition) =>
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

              final upgradedOrTmpTables = await _getCurrentTables(db);
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
    TableDefinitionV2 tableDefinition,
  ) async {
    final createTableSql = tableDefinition.buildCreateTableSql();
    info("Create table: \"$createTableSql\".");
    await db.execute(createTableSql);
  }

  static Future<List<Map<String, Object?>>> _getCurrentTables(
    sqflite.Database db,
  ) =>
      db.query(
        "sqlite_master",
        where: "NOT(name = ?) AND NOT(name = ?)",
        whereArgs: ["android_metadata", "sqlite_sequence"],
        orderBy: "rootpage DESC",
      );
}
