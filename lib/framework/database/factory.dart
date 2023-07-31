import 'package:flutter/foundation.dart';
import 'package:mem/logger/log_service.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite;

import 'accessor.dart';
import 'definition/database_definition_v2.dart';

class DatabaseFactory {
  static Future<DatabaseAccessor> open(
    DatabaseDefinitionV2 databaseDefinition,
  ) =>
      i(
        () async {
          final factory = nativeFactory;

          final nativeDatabase = await factory.openDatabase(
            await buildDatabasePath(databaseDefinition.name),
            options: sqflite.OpenDatabaseOptions(
              version: databaseDefinition.version,
              onConfigure: (db) => i(
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
              ),
              onCreate: (db, version) => i(
                () async {
                  for (final tableDefinition
                      in databaseDefinition.tableDefinitions) {
                    final createTableSql =
                        tableDefinition.buildCreateTableSql();
                    info("Create table :: \"$createTableSql\".");
                    await db.execute(createTableSql);
                  }
                },
                [db, version],
              ),
            ),
          );

          return DatabaseAccessor(nativeDatabase);
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
}
