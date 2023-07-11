import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

import 'definitions.dart';

void main() {
  LogService.initialize(Level.verbose);
  testDatabaseV2();
}

const _scenarioName = 'Database test V2';

void testDatabaseV2() => group(': $_scenarioName', () {
      late final sqflite.DatabaseFactory factory;
      late final String databasePath;

      setUpAll(() async {
        String databaseDirectoryPath;
        if (Platform.isAndroid) {
          factory = sqflite.databaseFactory;
          databaseDirectoryPath = await sqflite.getDatabasesPath();
        } else {
          sqflite_ffi.sqfliteFfiInit();
          factory = sqflite_ffi.databaseFactoryFfi;
          databaseDirectoryPath = (await getApplicationSupportDirectory()).path;
        }

        databasePath =
            path.join(databaseDirectoryPath, testDatabaseDefinition.name);

        await factory.deleteDatabase(databasePath);
      });

      test(': open', () async {
        final database = await factory.openDatabase(
          databasePath,
          options: sqflite.OpenDatabaseOptions(
            version: testDatabaseDefinition.version,
            onCreate: (db, version) async {
              info('Create Database :: $testDatabaseDefinition.');
              for (var tableDefinition
                  in testDatabaseDefinition.tableDefinitions) {
                info('Create table :: $tableDefinition.');
                await db.execute(
                  verbose(tableDefinition.buildCreateTableSql()),
                );
              }
            },
          ),
        );

        expect(
          path.split(database.path).last,
          testDatabaseDefinition.name,
        );
        expect(
          (await database.query(
            'sqlite_master',
            where: 'name = ?',
            whereArgs: [
              testTableDefinition.name,
            ],
          ))
              .single['sql'],
          testTableDefinition.buildCreateTableSql(),
        );
        expect(
          (await database.query(
            'sqlite_master',
            where: 'name = ?',
            whereArgs: [
              testChildTableDefinition.name,
            ],
          ))
              .single['sql'],
          testChildTableDefinition.buildCreateTableSql(),
        );
      });
    });
