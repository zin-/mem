import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/factory.dart';

import 'database_definitions.dart';

const _name = "Database accessor test";

void main() => group(
      "$_name: operations",
      () {
        final inserted = {
          sampleDefPk.name: 0,
          sampleDefColInteger.name: 0,
          sampleDefColText.name: "$_name: operations: inserted",
          sampleDefColTimeStamp.name: DateTime(0),
          sampleDefColBoolean.name: false,
        };

        late final DatabaseAccessor databaseAccessor;
        late final int maxPkInsertedId;
        setUpAll(() async {
          await DatabaseFactory
              // ignore: deprecated_member_use_from_same_package
              .nativeFactory
              .deleteDatabase(
                  await DatabaseFactory.buildDatabasePath(sampleDefDb.name));

          databaseAccessor = await DatabaseFactory.open(sampleDefDBAddedColumn);

          await databaseAccessor
              // ignore: deprecated_member_use_from_same_package
              .nativeDatabase
              .insert(sampleDefTable.name, {
            ...inserted,
            sampleDefColTimeStamp.name:
                (inserted[sampleDefColTimeStamp.name] as DateTime)
                    .toIso8601String(),
            sampleDefColBoolean.name:
                (inserted[sampleDefColBoolean.name] as bool) ? 1 : 0,
          });

          maxPkInsertedId = ((await databaseAccessor
                      // ignore: deprecated_member_use_from_same_package
                      .nativeDatabase
                      .query(
                sampleDefTable.name,
                orderBy: "${sampleDefPk.name} DESC",
                limit: 1,
              ))
                  .singleWhereOrNull((element) => true)?[sampleDefPk.name] ??
              0) as int;
        });

        test(": insert.", () async {
          final insertedId = await databaseAccessor.insert(sampleDefTable, {
            sampleDefColInteger.name: 1,
            sampleDefColText.name: "$_name: operations: insert",
            sampleDefColTimeStamp.name: DateTime.now(),
            sampleDefColBoolean.name: true,
          });

          expect(insertedId, maxPkInsertedId + 1);
        });

        test(": select.", () async {
          final selected = await databaseAccessor.select(
            sampleDefTable,
            orderBy: "${sampleDefPk.name} ASC",
            limit: 1,
          );

          expect(selected, [inserted]);
        });

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
