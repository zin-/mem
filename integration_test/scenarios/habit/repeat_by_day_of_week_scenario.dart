import 'package:collection/collection.dart';
import 'package:day_picker/day_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/features/mems/detail/fab.dart';
import 'package:mem/features/mem_notifications/mem_notifications_view.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/notifications/mem_notifications.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/framework/notifications/notification_ids.dart';
import 'package:mem/framework/notifications/schedule_client.dart';
import 'package:mem/values/constants.dart';
import 'package:mem/values/durations.dart';

import '../helpers.dart';

const _scenarioName = 'Repeat by day of week scenario';

void main() => group(
      _scenarioName,
      () {
        const baseMemName = "$_scenarioName - mem - name";
        const insertedMemName = "$baseMemName - inserted";

        final insertedMemNotificationTime =
            DateTime.now().subtract(const Duration(days: 1));

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
            defColMemNotificationsTime.name:
                insertedMemNotificationTime.weekday,
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
            defColMemNotificationsTime.name:
                DateTime.now().add(const Duration(days: 1)).weekday,
            defColMemNotificationsType.name:
                MemNotificationType.repeatByDayOfWeek.name,
            defColMemNotificationsMessage.name:
                "$_scenarioName - mem notification - repeatByDayOfWeek - message - inserted",
            defColCreatedAt.name: zeroDate,
          });
        });

        group(
          'Show',
          () {
            testWidgets(
              'No selected.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pump();
                await widgetTester.tap(newMemFabFinder);
                await widgetTester.pumpAndSettle();
                final notificationAddFinder = find.descendant(
                    of: find.byKey(keyMemNotificationsView),
                    matching: find.byIcon(Icons.notification_add));
                await widgetTester.dragUntilVisible(notificationAddFinder,
                    find.byType(SingleChildScrollView), const Offset(0, 50));
                await widgetTester.tap(notificationAddFinder);
                await widgetTester.pumpAndSettle();

                for (var dayOfWeek in [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ]) {
                  expect(find.text(dayOfWeek), findsOneWidget);
                }
                expect(
                  widgetTester
                      .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                      .days
                      .map((e) => e.isSelected),
                  everyElement(false),
                );
              },
            );

            testWidgets(
              'Week day of yesterday is selected.',
              (widgetTester) async {
                final repeatText =
                    DateFormat.E().format(insertedMemNotificationTime);

                await runApplication();
                await widgetTester.pumpAndSettle();

                expect(find.text(repeatText), findsOneWidget);
                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();

                expect(
                  widgetTester
                      .widget<Text>(find.descendant(
                          of: find.byKey(keyMemNotificationsView),
                          matching: find.byType(Text)))
                      .data,
                  equals(repeatText),
                );

                await widgetTester.tap(find.descendant(
                    of: find.byKey(keyMemNotificationsView),
                    matching: find.byIcon(Icons.edit)));
                await widgetTester.pumpAndSettle();

                expect(
                  widgetTester
                      .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                      .days[insertedMemNotificationTime.weekday - 1]
                      .isSelected,
                  isTrue,
                );
                expect(
                  widgetTester
                      .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                      .days
                      .whereIndexed((index, element) =>
                          index != insertedMemNotificationTime.weekday - 1)
                      .map((e) => e.isSelected),
                  everyElement(isFalse),
                );
              },
            );
          },
        );

        group(
          'Change',
          () {
            testWidgets(
              'Select Mon, Fri.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(newMemFabFinder);
                await widgetTester.pumpAndSettle();
                final notificationAddFinder = find.descendant(
                    of: find.byKey(keyMemNotificationsView),
                    matching: find.byIcon(Icons.notification_add));
                await widgetTester.dragUntilVisible(notificationAddFinder,
                    find.byType(SingleChildScrollView), const Offset(0, 50));
                await widgetTester.tap(notificationAddFinder);
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
                  isTrue,
                );
                expect(
                  widgetTester
                      .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                      .days[4]
                      .isSelected,
                  isTrue,
                );
                expect(
                  widgetTester
                      .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                      .days
                      .whereIndexed(
                          (index, element) => index != 0 && index != 4)
                      .map((e) => e.isSelected),
                  everyElement(isFalse),
                );
              },
            );

            testWidgets(
              'Unselect selected.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle(defaultTransitionDuration);
                await widgetTester.tap(find.descendant(
                    of: find.byKey(keyMemNotificationsView),
                    matching: find.byIcon(Icons.edit)));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find
                    .text(DateFormat.E().format(insertedMemNotificationTime)));

                expect(
                  widgetTester
                      .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                      .days
                      .map((e) => e.isSelected),
                  everyElement(false),
                );
              },
            );
          },
        );

        testWidgets(
          'Save.',
          (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
            widgetTester.ignoreMockMethodCallHandler(
                MethodChannelMock.permissionHandler);

            await runApplication();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle(defaultTransitionDuration);
            await widgetTester.tap(find.descendant(
                of: find.byKey(keyMemNotificationsView),
                matching: find.byIcon(Icons.edit)));
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(
                find.text(DateFormat.E().format(insertedMemNotificationTime)));
            await widgetTester.tap(find.text('Sun'));

            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byKey(keySaveMemFab));
            await widgetTester.pumpAndSettle(waitSideEffectDuration);

            await widgetTester.tap(find.descendant(
                of: find.byKey(keyMemNotificationsView),
                matching: find.byIcon(Icons.edit)));
            await widgetTester.pumpAndSettle();

            expect(
              widgetTester
                  .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                  .days[6]
                  .isSelected,
              isTrue,
            );
            expect(
              widgetTester
                  .widget<SelectWeekDays>(find.byType(SelectWeekDays))
                  .days
                  .whereIndexed((i, e) => i != 6)
                  .map((e) => e.isSelected),
              everyElement(isFalse),
            );

            final savedMemNotifications =
                await dbA.select(defTableMemNotifications);
            expect(savedMemNotifications, hasLength(3));
            expect(
              savedMemNotifications.singleWhere(
                (e) =>
                    e[defFkMemNotificationsMemId.name] == insertedMemId &&
                    e[defColMemNotificationsType.name] ==
                        MemNotificationType.repeatByDayOfWeek.name,
              )[defColMemNotificationsTime.name],
              equals(7),
            );
          },
        );

        group(
          'scheduleCallback',
          () {
            setUp(() async {
              NotificationClient.resetSingleton();
            });

            testWidgets(
              'Notify.',
              (widgetTester) async {
                int requestPermissionsCount = 0;
                widgetTester.setMockMethodCallHandler(MethodChannelMock.mem, [
                  (m) async {
                    expect(m.method, requestPermissions);
                    requestPermissionsCount++;
                    return true;
                  }
                ]);
                int initializeCount = 0;
                int cancelCount = 0;
                int showCount = 0;
                widgetTester.setMockMethodCallHandler(
                  MethodChannelMock.flutterLocalNotifications,
                  [
                    (message) async {
                      expect(message.method, equals('initialize'));
                      initializeCount++;
                      return true;
                    },
                    ...[
                      memStartNotificationId(notifyTodayMemId!),
                      memEndNotificationId(notifyTodayMemId!),
                      pausedActNotificationId(notifyTodayMemId!),
                      afterActStartedNotificationId(notifyTodayMemId!),
                    ].map(
                      (e) => (message) async {
                        expect(message.method, equals('cancel'));
                        expect(message.arguments['id'], equals(e));
                        cancelCount++;
                        return false;
                      },
                    ),
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

                expect(
                  requestPermissionsCount,
                  equals(
                      defaultTargetPlatform == TargetPlatform.android ? 1 : 0),
                  reason: 'requestPermissionsCount',
                );
                expect(
                  initializeCount,
                  equals(
                      defaultTargetPlatform == TargetPlatform.android ? 1 : 0),
                  reason: 'initializeCount',
                );
                expect(
                  cancelCount,
                  equals(
                      defaultTargetPlatform == TargetPlatform.android ? 4 : 0),
                  reason: 'cancelCount',
                );
                expect(
                  showCount,
                  equals(
                      defaultTargetPlatform == TargetPlatform.android ? 1 : 0),
                  reason: 'showCount',
                );

                widgetTester.clearAllMockMethodCallHandler();
              },
            );

            testWidgets(
              'not notify',
              (widgetTester) async {
                widgetTester.setMockMethodCallHandler(
                  MethodChannelMock.flutterLocalNotifications,
                  [],
                );

                await scheduleCallback(
                  1,
                  {
                    memIdKey: notifyTomorrowMemId,
                    notificationTypeKey: NotificationType.repeat.name,
                  },
                );

                widgetTester.clearAllMockMethodCallHandler();
              },
            );
          },
        );
      },
    );
