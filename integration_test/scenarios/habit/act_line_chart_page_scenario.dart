import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';

import '../helpers.dart';

const _name = "ActLineChartPage scenario";

void main() => group(
      _name,
      () {
        const insertedMemName = '$_name: inserted mem - name';

        late final DatabaseAccessor dbA;
        late final int insertedMemId;

        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
          await clearAllTestDatabaseRows(databaseDefinition);

          insertedMemId = await dbA.insert(
            defTableMems,
            {
              defColMemsName.name: insertedMemName,
              defColCreatedAt.name: zeroDate,
            },
          );
        });

        setUp(() async {
          await dbA.delete(defTableActs);

          final now = DateTime.now();

          await dbA.insert(
            defTableActs,
            {
              defFkActsMemId.name: insertedMemId,
              defColActsStart.name: DateTime(now.year, now.month - 1, 28),
              defColActsStartIsAllDay.name: 0,
              defColActsEnd.name: now,
              defColActsEndIsAllDay.name: 0,
              defColCreatedAt.name: zeroDate,
            },
          );
          for (int i = 0; i < 34; i++) {
            final start = now.subtract(Duration(days: i));
            for (int j = 0; j < randomInt(5); j++) {
              await dbA.insert(
                defTableActs,
                {
                  defFkActsMemId.name: insertedMemId,
                  defColActsStart.name: start,
                  defColActsStartIsAllDay.name: 0,
                  defColActsEnd.name: now,
                  defColActsEndIsAllDay.name: 0,
                  defColCreatedAt.name: zeroDate,
                },
              );
            }
          }
        });

        testWidgets(
          ": show chart",
          (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(
                MethodChannelMock.flutterLocalNotifications);

            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.show_chart));
            await widgetTester.pumpAndSettle();

            expect(true, isTrue);
          },
        );
      },
    );
