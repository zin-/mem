import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/factory.dart';

import 'database_definitions.dart';

const _name = "Database accessor test";

void main() => group(
      "$_name: operations",
      () {
        const insertedName = "$_name: operations: inserted";

        final inserted = {
          sampleDefPk.name: 1,
          sampleDefColInteger.name: 0,
          sampleDefColText.name: insertedName,
          sampleDefColTimeStamp.name: DateTime(0),
          sampleDefColBoolean.name: false,
        };
        final inserted2 = {
          sampleDefPk.name: 2,
          sampleDefColInteger.name: 1,
          sampleDefColText.name: "$insertedName - 2",
          sampleDefColTimeStamp.name: DateTime(1),
          sampleDefColBoolean.name: true,
        };
        final inserted3 = {
          sampleDefPk.name: 3,
          sampleDefColInteger.name: 3,
          sampleDefColText.name: "$insertedName - 3",
          sampleDefColTimeStamp.name: DateTime(3),
          sampleDefColBoolean.name: false,
        };

        late final DatabaseAccessor databaseAccessor;

        setUpAll(() async {
          await DatabaseFactory
              // ignore: deprecated_member_use_from_same_package
              .nativeFactory
              .deleteDatabase(
                  await DatabaseFactory.buildDatabasePath(sampleDefDb.name));

          databaseAccessor = await DatabaseFactory.open(sampleDefDBAddedColumn);
        });

        setUp(() async {
          await databaseAccessor
              // ignore: deprecated_member_use_from_same_package
              .nativeDatabase
              .delete(sampleDefTable.name);

          await databaseAccessor
              // ignore: deprecated_member_use_from_same_package
              .nativeDatabase
              .insert(
            sampleDefTable.name,
            {
              ...inserted,
              sampleDefColTimeStamp.name:
                  (inserted[sampleDefColTimeStamp.name] as DateTime)
                      .toIso8601String(),
              sampleDefColBoolean.name:
                  (inserted[sampleDefColBoolean.name] as bool) ? 1 : 0,
            },
          );
          await databaseAccessor
              // ignore: deprecated_member_use_from_same_package
              .nativeDatabase
              .insert(
            sampleDefTable.name,
            {
              ...inserted2,
              sampleDefColTimeStamp.name:
                  (inserted2[sampleDefColTimeStamp.name] as DateTime)
                      .toIso8601String(),
              sampleDefColBoolean.name:
                  (inserted2[sampleDefColBoolean.name] as bool) ? 1 : 0,
            },
          );
          await databaseAccessor
              // ignore: deprecated_member_use_from_same_package
              .nativeDatabase
              .insert(
            sampleDefTable.name,
            {
              ...inserted3,
              sampleDefColTimeStamp.name:
                  (inserted3[sampleDefColTimeStamp.name] as DateTime)
                      .toIso8601String(),
              sampleDefColBoolean.name:
                  (inserted3[sampleDefColBoolean.name] as bool) ? 1 : 0,
            },
          );
        });

        test(": insert.", () async {
          final maxPkInsertedId = ((await databaseAccessor
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase
                      .query(
                sampleDefTable.name,
                orderBy: "${sampleDefPk.name} DESC",
                limit: 1,
              ))
                  .singleWhereOrNull((element) => true)?[sampleDefPk.name] ??
              0) as int;

          final insertedId = await databaseAccessor.insert(sampleDefTable, {
            sampleDefColInteger.name: 1,
            sampleDefColText.name: "$_name: operations: insert",
            sampleDefColTimeStamp.name: DateTime.now(),
            sampleDefColBoolean.name: true,
          });

          expect(insertedId, maxPkInsertedId + 1);
        });

        test(
          ": count.",
          () async {
            final count = await databaseAccessor.count(sampleDefTable);

            expect(count, equals(3));
          },
        );

        group(
          ": select",
          () {
            test(
              ": simple.",
              () async {
                final selected = await databaseAccessor.select(sampleDefTable);

                expect(selected, [inserted, inserted2, inserted3]);
              },
            );

            test(
              'group by.',
              () async {
                final extraColumn = 'MAX( ${sampleDefPk.name} )';
                final selected = await databaseAccessor.select(
                  sampleDefTable,
                  groupBy: sampleDefColBoolean.name,
                  extraColumns: [extraColumn],
                );

                expect(selected, [
                  {...inserted3, extraColumn: inserted3[sampleDefPk.name]},
                  {...inserted2, extraColumn: inserted2[sampleDefPk.name]},
                ]);
              },
            );

            test(
              ": where.",
              () async {
                final selected = await databaseAccessor.select(
                  sampleDefTable,
                  where: "${sampleDefPk.name} = ?",
                  whereArgs: [inserted2[sampleDefPk.name]],
                );

                expect(selected, [inserted2]);
              },
            );

            test(
              ": orderBy.",
              () async {
                final selected = await databaseAccessor.select(
                  sampleDefTable,
                  orderBy: "${sampleDefPk.name} DESC",
                );

                expect(selected, [inserted3, inserted2, inserted]);
              },
            );

            test(
              ": offset.",
              () async {
                final selected = await databaseAccessor.select(
                  sampleDefTable,
                  offset: 1,
                );

                expect(selected, [inserted2, inserted3]);
              },
            );

            test(
              ": limit.",
              () async {
                final selected = await databaseAccessor.select(
                  sampleDefTable,
                  limit: 1,
                );

                expect(selected, [inserted]);
              },
            );
          },
        );

        test(": update.", () async {
          final updatedCount = await databaseAccessor.update(
            sampleDefTable,
            {
              sampleDefColInteger.name: 999,
              sampleDefColText.name: "$_name: operations: update",
              sampleDefColBoolean.name: false,
            },
            where: "${sampleDefPk.name} = ?",
            whereArgs: [inserted[sampleDefPk.name]],
          );

          expect(updatedCount, 1);
        });

        test(": delete.", () async {
          final updatedCount = await databaseAccessor.delete(
            sampleDefTable,
            where: "${sampleDefPk.name} = ?",
            whereArgs: [inserted[sampleDefPk.name]],
          );

          expect(updatedCount, 1);
        });
      },
    );
