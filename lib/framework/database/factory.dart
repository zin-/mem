import 'package:flutter/foundation.dart';
import 'package:mem/framework/database/definition/table_definition_v2.dart';
import 'package:mem/logger/log_service.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart' as sqflite_api;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;
import 'accessor.dart';
import 'definition/database_definition_v2.dart';

class DatabaseFactory {
  static final _databaseAccessors = <String, DatabaseAccessor>{};

  // TODO add upgrade
  // TODO add on test
  // TODO? already opened situation
  static Future<DatabaseAccessor> open(
    DatabaseDefinitionV2 databaseDefinition,
  ) =>
      i(
        () async {
          if (_databaseAccessors.containsKey(databaseDefinition.name)) {
            final databaseAccessor =
                _databaseAccessors[databaseDefinition.name];

            if (databaseAccessor!.nativeDatabase.isOpen) {
              try {
                await databaseAccessor.nativeDatabase.getVersion();

                return databaseAccessor;
              } on sqflite_api.DatabaseException catch (e) {
                final exceptionMessage = e.toString();
                if (exceptionMessage.startsWith(
                      "DatabaseException(database_closed ",
                    ) ||
                    exceptionMessage.startsWith(
                      "SqfliteFfiException(error, Bad state: This database has already been closed})",
                    )) {
                  // nativeDatabaseがcloseされずに直接deleteされた場合にこの状況になる
                  // 本来ならこのクラスではなく、sqflite_apiの責務だと考えているが、
                  // 考慮されていないのでここで対処する
                  _databaseAccessors.remove(databaseDefinition.name);
                  await databaseAccessor.nativeDatabase.close();
                } else {
                  rethrow;
                }
              }
            }
          }

          final databaseAccessor = DatabaseAccessor(
            await nativeFactory.openDatabase(
              await buildDatabasePath(databaseDefinition.name),
              options: sqflite.OpenDatabaseOptions(
                version: databaseDefinition.version,
                onConfigure: _onConfigure(databaseDefinition),
                onCreate: _onCreate(databaseDefinition),
              ),
            ),
          );

          return _databaseAccessors.update(
            databaseDefinition.name,
            (value) => databaseAccessor,
            ifAbsent: () => databaseAccessor,
          );
        },
        databaseDefinition,
      );

  static sqflite.DatabaseFactory get nativeFactory {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      sqflite.sqfliteFfiInit();
      return sqflite.databaseFactoryFfi;
    }

    return sqflite.databaseFactory;
  }

  static Future<String> buildDatabasePath(String databaseName) async =>
      path.join(
        await nativeFactory.getDatabasesPath(),
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

  static Future<void> _executeCreateTableSql(
    sqflite.Database db,
    TableDefinitionV2 tableDefinition,
  ) async {
    final createTableSql = tableDefinition.buildCreateTableSql();
    info("Create table: \"$createTableSql\".");
    await db.execute(createTableSql);
  }
}
