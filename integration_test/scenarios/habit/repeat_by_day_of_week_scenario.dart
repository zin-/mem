import 'package:collection/collection.dart';
import 'package:day_picker/day_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/mems/detail/fab.dart';
import 'package:mem/mems/detail/notifications/mem_notifications_view.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/values/durations.dart';

import '../helpers.dart';

const _scenarioName = 'Repeat by day of week scenario';

void main() => group(
      _scenarioName,
      () {
        const baseMemName = "$_scenarioName - mem - name";
        const insertedMemName = "$baseMemName - inserted";

        late final DatabaseAccessor dbA;

        int? insertedMemId;
        int? notifyTodayMemId;
        int? notifyTomorrowMemId;
        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
          await clearAllTestDatabaseRows(databaseDefinition);

          insertedMemId = await dbA.insert(defTableMems, {
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
          notifyTodayMemId = await dbA.insert(defTableMems, {
            defColMemsName.name: baseMemName,
            defColMemsDoneAt.name: null,
            defColCreatedAt.name: zeroDate
          });
          await dbA.insert(defTableMemNotifications, {
            defFkMemNotificationsMemId.name: notifyTodayMemId,
            defColMemNotificationsTime.name: DateTime.now().weekday,
            defColMemNotificationsType.name:
                MemNotificationType.repeatByDayOfWeek.name,
            defColMemNotificationsMessage.name:
                "$_scenarioName - mem notification - repeatByDayOfWeek - message - inserted",
            defColCreatedAt.name: zeroDate,
          });
          notifyTomorrowMemId = await dbA.insert(defTableMems, {
            defColMemsName.name: baseMemName,
            defColMemsDoneAt.name: null,
            defColCreatedAt.name: zeroDate
          });
          await dbA.insert(defTableMemNotifications, {
            defFkMemNotificationsMemId.name: notifyTomorrowMemId,
            defColMemNotificationsTime.name: DateTime.now().weekday + 1,
            defColMemNotificationsType.name:
                MemNotificationType.repeatByDayOfWeek.name,
            defColMemNotificationsMessage.name:
                "$_scenarioName - mem notification - repeatByDayOfWeek - message - inserted",
            defColCreatedAt.name: zeroDate,
          });
        });

        setUp(() async {
          NotificationClient.resetSingleton();
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

        testWidgets(
          "save.",
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
            await widgetTester.tap(find.text('Sun'));

            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byKey(keySaveMemFab));
            await widgetTester.pumpAndSettle(waitSideEffectDuration);

            await widgetTester.tap(find.descendant(
                of: find.byKey(keyMemNotificationsView),
                matching: find.byIcon(Icons.edit)));
            await widgetTester.pumpAndSettle();

            final savedMemNotification = await dbA.select(
                defTableMemNotifications,
                where: "${defFkMemNotificationsMemId.name} = ?",
                whereArgs: [insertedMemId],
                orderBy: "id ASC");
            expect(savedMemNotification, hasLength(1));
            expect(savedMemNotification[0][defColMemNotificationsTime.name],
                equals(6));
            expect(
                widgetTester
                    .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                    .days[6]
                    .isSelected,
                isTrue);
            expect(
                widgetTester
                    .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                    .days
                    .whereIndexed((index, element) => index != 6)
                    .map((e) => e.isSelected),
                everyElement(isFalse));
          },
        );

        group(
          'scheduleCallback',
          () {
            testWidgets(
              'notify',
              (widgetTester) async {
                int initializeCount = 0;
                int showCount = 0;
                widgetTester.setMockFlutterLocalNotifications(
                  [
                    (message) async {
                      expect(message.method, equals('initialize'));
                      initializeCount++;
                      return true;
                    },
                    (message) async {
                      expect(message.method, equals('show'));
                      expect(message.arguments['id'],
                          equals(memRepeatedNotificationId(notifyTodayMemId!)));
                      expect(message.arguments['title'], equals(baseMemName));
                      expect(message.arguments['body'], equals("Repeat"));
                      expect(message.arguments['payload'],
                          equals("{\"$memIdKey\":$notifyTodayMemId}"));
                      showCount++;
                      return false;
                    },
                  ],
                );

                await scheduleCallback(
                  1,
                  {
                    memIdKey: notifyTodayMemId,
                    notificationTypeKey: NotificationType.repeat.name,
                  },
                );

                if (defaultTargetPlatform == TargetPlatform.android) {
                  expect(initializeCount, equals(1));
                  expect(showCount, equals(1));
                } else {
                  expect(initializeCount, equals(0));
                  expect(showCount, equals(0));
                }

                widgetTester.clearMockFlutterLocalNotifications();
              },
            );

            testWidgets(
              'not notify',
              (widgetTester) async {
                widgetTester.setMockFlutterLocalNotifications(
                  [],
                );

                await scheduleCallback(
                  1,
                  {
                    memIdKey: notifyTomorrowMemId,
                    notificationTypeKey: NotificationType.repeat.name,
                  },
                );

                widgetTester.clearMockFlutterLocalNotifications();
              },
            );
          },
        );
      },
    );
