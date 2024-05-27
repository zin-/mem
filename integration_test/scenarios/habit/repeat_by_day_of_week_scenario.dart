import 'package:day_picker/day_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/mems/detail/notifications/mem_notifications_view.dart';
import 'package:mem/values/durations.dart';

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
              'initial.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pump();
                await widgetTester.tap(newMemFabFinder);
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.descendant(
                    of: find.byKey(keyMemNotificationsView),
                    matching: find.byIcon(Icons.notification_add)));
                await widgetTester.pumpAndSettle();

                for (var dayOfWeek in [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun'
                ]) {
                  expect(find.text(dayOfWeek), findsOneWidget);
                }
                expect(
                    widgetTester
                        .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                        .days
                        .map((e) => e.isSelected),
                    everyElement(false));
              },
            );

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

                await widgetTester.tap(find.descendant(
                    of: find.byKey(keyMemNotificationsView),
                    matching: find.byIcon(Icons.edit)));
                await widgetTester.pumpAndSettle();

                expect(
                    widgetTester
                        .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                        .days[0]
                        .isSelected,
                    isTrue);
              },
            );
          },
        );

        group(
          'change',
          () {
            testWidgets(
              'select Mon, Fri.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pump();
                await widgetTester.tap(newMemFabFinder);
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.descendant(
                    of: find.byKey(keyMemNotificationsView),
                    matching: find.byIcon(Icons.notification_add)));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text('Mon'));
                await widgetTester.pump();
                await widgetTester.tap(find.text('Fri'));
                await widgetTester.pump();

                expect(
                    widgetTester
                        .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                        .days[0]
                        .isSelected,
                    isTrue);
                expect(
                    widgetTester
                        .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                        .days[4]
                        .isSelected,
                    isTrue);
              },
            );

            testWidgets(
              'unselect Mon.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle(defaultTransitionDuration);
                await widgetTester.tap(find.descendant(
                    of: find.byKey(keyMemNotificationsView),
                    matching: find.byIcon(Icons.edit)));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text('Mon'));

                expect(
                    widgetTester
                        .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                        .days
                        .map((e) => e.isSelected),
                    everyElement(false));
              },
            );
          },
        );
      },
    );
