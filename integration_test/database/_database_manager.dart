import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/database/sqlite_database.dart';
import 'package:mem/logger.dart';

import 'definitions.dart';

void main() {
  Logger(level: Level.verbose);

  testDatabaseManager();
}

void testDatabaseManager() => group(
      'DatabaseManager test',
      () {
        if (Platform.isAndroid || Platform.isWindows) {
          setUp(() async {
            await DatabaseManager().delete(defD.name);
          });

          test(
            'Open database twice.',
            () async {
              final db = await DatabaseManager().open(defD);
              if (kIsWeb) {
                expect(db, isA<IndexedDatabase>());
              } else {
                expect(db, isA<SqliteDatabase>());
              }

              final openedDb = await DatabaseManager().open(defD);
              expect(openedDb, db);
            },
            tags: 'Medium',
          );

          test(
            'Open and close database.',
            () async {
              const tName = 'tests';
              final db = await DatabaseManager().open(defD);
              final table = db.getTable(tName);

              final closeResult1 = await DatabaseManager().close(defD.name);
              expect(closeResult1, true);
              final closeResult2 = await DatabaseManager().close(defD.name);
              expect(closeResult2, false);

              final directCloseResult = await db.close();
              expect(directCloseResult, false);

              expect(
                () => table.insert({}),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
              expect(
                () => table.select(),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
              expect(
                () => table.selectByPk(1),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
              expect(
                () => table.updateByPk(1, {}),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
              expect(
                () => table.delete(),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
              expect(
                () => table.deleteByPk(1),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
            },
            tags: 'Medium',
          );

          test(
            'Open and delete database.',
            () async {
              final db = await DatabaseManager().open(defD);
              final table = db.getTable(tableName);

              final deleteResult1 = await DatabaseManager().delete(defD.name);
              expect(deleteResult1, true);
              final deleteResult2 = await DatabaseManager().delete(defD.name);
              expect(deleteResult2, false);

              final directDeleteResult = await db.delete();
              expect(directDeleteResult, false);

              expect(
                () => table.insert({}),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
              expect(
                () => table.select(),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
              expect(
                () => table.selectByPk(1),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
              expect(
                () => table.updateByPk(1, {}),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
              expect(
                () => table.delete(),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
              expect(
                () => table.deleteByPk(1),
                throwsA((e) => e is DatabaseDoesNotExistException),
              );
            },
            tags: 'Medium',
          );
        }
      },
    );
