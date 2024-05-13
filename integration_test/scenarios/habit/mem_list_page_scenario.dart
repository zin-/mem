import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/timer.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';

import '../helpers.dart';

const _name = "MemListPage scenario";

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
          await dbA.insert(
            defTableMemNotifications,
            {
              defFkMemNotificationsMemId.name: insertedMemId,
              defColMemNotificationsTime.name: 1,
              defColMemNotificationsType.name:
                  MemNotificationType.afterActStarted.name,
              defColMemNotificationsMessage.name:
                  '$_name: mem notification message',
              defColCreatedAt.name: zeroDate,
            },
          );

          await dbA.insert(
            defTableMems,
            {
              defColMemsName.name: "$insertedMemName - 2",
              defColCreatedAt.name: zeroDate,
            },
          );
        });

        setUp(() async {
          await dbA.delete(defTableActs);

          dbA.insert(defTableActs, {
            defFkActsMemId.name: insertedMemId,
            defColActsStart.name: zeroDate,
            defColActsStartIsAllDay.name: false,
            defColCreatedAt.name: zeroDate,
          });
        });

        testWidgets(
          ": start act.",
          // 時間に関するテストなので3回までリトライ可能とする
          retry: 3,
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(startIconFinder);
            await widgetTester.pumpAndSettle();

            expect(
              widgetTester.widget<Text>(find.byType(Text).at(3)).data,
              '00:00:00',
            );

            expect(startIconFinder, findsNothing);
            expect(stopIconFinder, findsNWidgets(2));
            await widgetTester.pumpAndSettle(elapsePeriod);

            expect(find.text('00:00:00'), findsNothing);
          },
        );

        testWidgets(": finish act.", (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(stopIconFinder);
          await widgetTester.pump();

          expect(startIconFinder, findsNWidgets(2));
          expect(stopIconFinder, findsNothing);
        });
      },
    );
