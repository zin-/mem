import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/mems/detail/notifications/mem_notifications_view.dart';

import '../helpers.dart';

const _scenarioName = 'Repeat by day of week scenario';

void main() => group(
      _scenarioName,
      () {
        const baseMemName = "$_scenarioName - mem - name";

        late final DatabaseAccessor dbA;
        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });

        const insertedMemName = "$baseMemName - inserted";

        setUp(() async {
          await clearAllTestDatabaseRows(databaseDefinition);

          final insertedMemId = await dbA.insert(defTableMems, {
            defColMemsName.name: insertedMemName,
            defColMemsDoneAt.name: null,
            defColCreatedAt.name: zeroDate
          });
          await dbA.insert(defTableMemNotifications, {
            defFkMemNotificationsMemId.name: insertedMemId,
            defColMemNotificationsTime.name: 0,
            defColMemNotificationsType.name:
                MemNotificationType.repeatByDayOfWeek.name,
            defColMemNotificationsMessage.name:
                "$_scenarioName - mem notification - repeatByDayOfWeek - message - inserted",
            defColCreatedAt.name: zeroDate,
          });
        });

        group(
          'show',
          () {
            testWidgets(
              'saved.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                expect(
                    widgetTester
                        .widget<Text>(
                          find.descendant(
                              of: find.byKey(keyMemNotificationsView),
                              matching: find.byType(Text)),
                        )
                        .data,
                    equals("Mon"));
              },
            );
          },
        );
      },
    );
