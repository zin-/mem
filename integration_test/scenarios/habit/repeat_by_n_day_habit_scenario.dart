import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/mems/mem_name.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/mems/detail/fab.dart';
import 'package:mem/mems/detail/notifications/mem_notifications_view.dart';
import 'package:mem/mems/detail/notifications/mem_repeat_by_n_day_notification_view.dart';
import 'package:mem/notifications/notification_client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/schedule_client.dart';
import 'package:mem/values/constants.dart';
import 'package:mem/values/durations.dart';

import '../helpers.dart';

const _name = 'Repeat by n day habit scenario';

void main() => group(': $_name', () {
      const insertedMemName = "$_name - mem name - inserted";
      const insertedMemRepeatByNDay = 2;
      const withoutActMemName = "$insertedMemName - without act";
      const withOldActMemName = "$insertedMemName - with old act";
      const withCurrentActMemName = "$insertedMemName - with current act";
      const insertedRepeatNotificationMessage =
          "$_name - inserted - mem notification message - repeat";

      late final DatabaseAccessor dbA;

      int insertedMemId = 0;
      int withoutActMemId = 0;
      int withOldActMemId = 0;
      int withCurrentActMemId = 0;

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
            defColMemNotificationsType.name: MemNotificationType.repeat.name,
            defColMemNotificationsTime.name: 1,
            defColMemNotificationsMessage.name: "never",
            defColCreatedAt.name: zeroDate,
          },
        );
        await dbA.insert(defTableMemNotifications, {
          defFkMemNotificationsMemId.name: insertedMemId,
          defColMemNotificationsType.name:
              MemNotificationType.repeatByNDay.name,
          defColMemNotificationsTime.name: insertedMemRepeatByNDay,
          defColMemNotificationsMessage.name: "never",
          defColCreatedAt.name: zeroDate
        });

        withoutActMemId = await dbA.insert(defTableMems, {
          defColMemsName.name: withoutActMemName,
          defColMemsDoneAt.name: null,
          defColCreatedAt.name: zeroDate,
        });
        withOldActMemId = await dbA.insert(defTableMems, {
          defColMemsName.name: withOldActMemName,
          defColMemsDoneAt.name: null,
          defColCreatedAt.name: zeroDate
        });
        withCurrentActMemId = await dbA.insert(defTableMems, {
          defColMemsName.name: withCurrentActMemName,
          defColMemsDoneAt.name: null,
          defColCreatedAt.name: zeroDate
        });

        [withoutActMemId, withOldActMemId, withCurrentActMemId]
            .forEachIndexed((index, insertedMemId) async {
          await dbA.insert(defTableMemNotifications, {
            defFkMemNotificationsMemId.name: insertedMemId,
            defColMemNotificationsTime.name: 0,
            defColMemNotificationsType.name: MemNotificationType.repeat.name,
            defColMemNotificationsMessage.name:
                insertedRepeatNotificationMessage,
            defColCreatedAt.name: zeroDate
          });
          await dbA.insert(defTableMemNotifications, {
            defFkMemNotificationsMemId.name: insertedMemId,
            defColMemNotificationsTime.name:
                index + insertedMemRepeatByNDay + 1,
            defColMemNotificationsType.name:
                MemNotificationType.repeatByNDay.name,
            defColMemNotificationsMessage.name:
                "$_name - inserted - mem notification message - after act started",
            defColCreatedAt.name: zeroDate
          });
        });

        await dbA.insert(defTableActs, {
          defFkActsMemId.name: withOldActMemId,
          defColActsStart.name: zeroDate.toIso8601String(),
          defColActsStartIsAllDay.name: 0,
          defColCreatedAt.name: zeroDate
        });
        await dbA.insert(defTableActs, {
          defFkActsMemId.name: withCurrentActMemId,
          defColActsStart.name: DateTime.now().toIso8601String(),
          defColActsStartIsAllDay.name: 0,
          defColCreatedAt.name: zeroDate
        });
      });

      setUp(() async {
        NotificationClient.resetSingleton();
      });

      testWidgets(
        'show saved.',
        (widgetTester) async {
          widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications);

          const repeatText = "12:00 AM every $insertedMemRepeatByNDay days";

          await runApplication();
          await widgetTester.pumpAndSettle(defaultTransitionDuration);

          expect(find.text(repeatText), findsOneWidget);
          await widgetTester.tap(find.text(insertedMemName));
          await widgetTester.pumpAndSettle(defaultTransitionDuration);

          expect(
              widgetTester
                  .widget<Text>(find.descendant(
                      of: find.byKey(keyMemNotificationsView),
                      matching: find.byType(Text)))
                  .data,
              repeatText);

          await widgetTester.tap(find.descendant(
              of: find.byKey(keyMemNotificationsView),
              matching: find.byIcon(Icons.edit)));
          await widgetTester.pumpAndSettle(defaultTransitionDuration);

          expect(
              widgetTester
                  .widget<TextFormField>(
                    find.descendant(
                      of: find.byKey(keyMemRepeatByNDayNotification),
                      matching: find.byType(TextFormField),
                    ),
                  )
                  .initialValue,
              insertedMemRepeatByNDay.toString());
        },
      );

      testWidgets(': save.', (widgetTester) async {
        widgetTester.ignoreMockMethodCallHandler(
            MethodChannelMock.flutterLocalNotifications);

        final testStart = DateTime.now();
        var expectedSavedMemId =
            ((await dbA.select(defTableMems, orderBy: "id DESC", limit: 1))
                    .single[defPkId.name] as int) +
                1;

        int alarmServiceStartCount = 0;
        int alarmCancelCount = 0;
        int alarmPeriodicCount = 0;
        widgetTester
            .setMockMethodCallHandler(MethodChannelMock.androidAlarmManager, [
          (message) async {
            expect(message.method, equals('AlarmService.start'));
            expect(message.arguments, orderedEquals([isNotNull]));
            alarmServiceStartCount++;
            return true;
          },
          (message) async {
            expect(message.method, equals('Alarm.cancel'));
            expect(
                message.arguments,
                orderedEquals(
                    [equals(memStartNotificationId(expectedSavedMemId))]));
            alarmCancelCount++;
            return false;
          },
          (message) async {
            expect(message.method, equals('Alarm.cancel'));
            expect(
                message.arguments,
                orderedEquals(
                    [equals(memEndNotificationId(expectedSavedMemId))]));
            alarmCancelCount++;
            return false;
          },
          (message) async {
            expect(message.method, equals('Alarm.periodic'));
            expect(message.arguments[0],
                equals(memRepeatedNotificationId(expectedSavedMemId)));
            expect(message.arguments[1], isFalse);
            expect(message.arguments[2], isFalse);
            expect(message.arguments[3], isFalse);
            expect(
                DateTime.fromMillisecondsSinceEpoch(message.arguments[4]),
                equals(testStart
                    .copyWith(
                        hour: defaultStartOfDay.hour,
                        minute: defaultStartOfDay.minute,
                        second: 0,
                        millisecond: 0,
                        microsecond: 0)
                    .add(const Duration(days: 1))));
            expect(
                message.arguments[5], const Duration(days: 1).inMilliseconds);
            expect(message.arguments[6], isFalse);
            expect(message.arguments[7], isNotNull);
            expect(
                message.arguments[8],
                equals({
                  memIdKey: expectedSavedMemId,
                  notificationTypeKey: NotificationType.repeat.name
                }));
            alarmPeriodicCount++;
            return false;
          },
        ]);

        await runApplication();
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(newMemFabFinder);
        await widgetTester.pumpAndSettle();
        const enteringMemName = "$_name: Save - entering - mem name";
        await widgetTester.enterText(find.byKey(keyMemName), enteringMemName);

        final notificationAddFinder = find.descendant(
            of: find.byKey(keyMemNotificationsView),
            matching: find.byIcon(Icons.notification_add));
        await widgetTester.tap(notificationAddFinder);
        await widgetTester.pumpAndSettle(defaultTransitionDuration);

        await widgetTester.tap(timeIconFinder);
        await widgetTester.pump();
        await widgetTester.tap(okFinder);
        await widgetTester.pump();

        const enteringNDay = 3;
        await widgetTester.enterText(
            find.descendant(
                of: find.byKey(keyMemRepeatByNDayNotification),
                matching: find.byType(TextFormField)),
            enteringNDay.toString());

        await widgetTester.pageBack();
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.byKey(keySaveMemFab));
        await widgetTester.pumpAndSettle(const Duration(seconds: 1));

        await widgetTester.runAsync(() async {
          final savedMem = (await dbA.select(
            defTableMems,
            where: "${defColMemsName.name} = ?",
            whereArgs: [enteringMemName],
          ))
              .single;
          final savedMemNotification = (await dbA.select(
                  defTableMemNotifications,
                  where: "${defFkMemNotificationsMemId.name} = ?"
                      " AND ${defColMemNotificationsType.name} = ?"
                      " AND ${defColMemNotificationsTime.name} = ?",
                  whereArgs: [
                savedMem[defPkId.name],
                MemNotificationType.repeatByNDay.name,
                enteringNDay
              ]))
              .single;
          expect(savedMemNotification[defColMemNotificationsTime.name],
              equals(enteringNDay),
              reason: 'enteringNDay');

          if (defaultTargetPlatform == TargetPlatform.android) {
            await expectLater(alarmServiceStartCount, equals(1),
                reason: 'alarmServiceStartCount');
            await expectLater(alarmCancelCount, equals(2),
                reason: 'alarmCancelCount');
            await expectLater(alarmPeriodicCount, equals(1),
                reason: 'alarmPeriodicCount');
          } else {
            await expectLater(alarmServiceStartCount, equals(0),
                reason: 'alarmServiceStartCount');
            await expectLater(alarmCancelCount, equals(0),
                reason: 'alarmCancelCount');
            await expectLater(alarmPeriodicCount, equals(0),
                reason: 'alarmPeriodicCount');
          }

          widgetTester.clearAllMockMethodCallHandler();
        });
      });

      group('notify repeatByNDay', () {
        testWidgets('withoutAct.', (widgetTester) async {
          int checkPermissionStatusCount = 0;
          widgetTester
              .setMockMethodCallHandler(MethodChannelMock.permissionHandler, [
            (m) async {
              expect(m.method, 'checkPermissionStatus');
              checkPermissionStatusCount++;
              return 1;
            }
          ]);
          int initializeCount = 0;
          int cancelCount = 0;
          int showCount = 0;
          widgetTester.setMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications, [
            (message) async {
              expect(message.method, equals('initialize'));
              initializeCount++;
              return true;
            },
            ...[
              memStartNotificationId(withoutActMemId),
              memEndNotificationId(withoutActMemId),
              pausedActNotificationId(withoutActMemId),
              afterActStartedNotificationId(withoutActMemId)
            ].map((e) => (message) async {
                  expect(message.method, equals('cancel'));
                  expect(message.arguments['id'], equals(e));
                  cancelCount++;
                  return false;
                }),
            (message) async {
              expect(message.method, equals('requestNotificationsPermission'));
              expect(message.arguments, isNull);
              return true;
            },
            (message) async {
              expect(message.method, equals('show'));
              expect(message.arguments['id'],
                  equals(memRepeatedNotificationId(withoutActMemId)));
              expect(message.arguments['title'], equals(withoutActMemName));
              expect(message.arguments['body'],
                  equals(insertedRepeatNotificationMessage));
              expect(message.arguments['payload'],
                  equals("{\"$memIdKey\":$withoutActMemId}"));
              showCount++;
              return false;
            }
          ]);

          final params = {
            memIdKey: withoutActMemId,
            notificationTypeKey: NotificationType.repeat.name,
          };

          await scheduleCallback(0, params);

          if (defaultTargetPlatform == TargetPlatform.android) {
            expect(checkPermissionStatusCount, equals(1),
                reason: 'checkPermissionStatusCount');
            expect(initializeCount, equals(1), reason: 'initializeCount');
            expect(cancelCount, equals(4), reason: 'cancelCount');
            expect(showCount, equals(1), reason: 'showCount');
          } else {
            expect(checkPermissionStatusCount, equals(1),
                reason: 'checkPermissionStatusCount');
            expect(initializeCount, equals(0), reason: 'initializeCount');
            expect(cancelCount, equals(0), reason: 'cancelCount');
            expect(showCount, equals(0), reason: 'showCount');
          }

          widgetTester.clearAllMockMethodCallHandler();
        });

        testWidgets('withOldAct', (widgetTester) async {
          int checkPermissionStatusCount = 0;
          widgetTester
              .setMockMethodCallHandler(MethodChannelMock.permissionHandler, [
            (m) async {
              expect(m.method, 'checkPermissionStatus');
              checkPermissionStatusCount++;
              return 1;
            }
          ]);
          int initializeCount = 0;
          int cancelCount = 0;
          int showCount = 0;
          widgetTester.setMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications, [
            (message) async {
              expect(message.method, equals('initialize'));
              initializeCount++;
              return true;
            },
            ...[
              memStartNotificationId(withOldActMemId),
              memEndNotificationId(withOldActMemId),
              pausedActNotificationId(withOldActMemId),
              afterActStartedNotificationId(withOldActMemId),
            ].map((e) => (message) async {
                  expect(message.method, equals('cancel'));
                  expect(message.arguments['id'], equals(e));
                  cancelCount++;
                  return false;
                }),
            (message) async {
              expect(message.method, equals('requestNotificationsPermission'));
              expect(message.arguments, isNull);
              return true;
            },
            (message) async {
              expect(message.method, equals('show'));
              expect(message.arguments['id'],
                  equals(memRepeatedNotificationId(withOldActMemId)));
              expect(message.arguments['title'], equals(withOldActMemName));
              expect(message.arguments['body'],
                  equals(insertedRepeatNotificationMessage));
              expect(message.arguments['payload'],
                  equals("{\"$memIdKey\":$withOldActMemId}"));
              showCount++;
              return false;
            }
          ]);

          final params = {
            memIdKey: withOldActMemId,
            notificationTypeKey: NotificationType.repeat.name
          };

          await scheduleCallback(0, params);

          if (defaultTargetPlatform == TargetPlatform.android) {
            expect(checkPermissionStatusCount, equals(1),
                reason: 'checkPermissionStatusCount');
            expect(initializeCount, equals(1), reason: 'initializeCount');
            expect(cancelCount, equals(4), reason: 'cancelCount');
            expect(showCount, equals(1), reason: 'showCount');
          } else {
            expect(checkPermissionStatusCount, equals(1),
                reason: 'checkPermissionStatusCount');
            expect(initializeCount, equals(0), reason: 'initializeCount');
            expect(cancelCount, equals(0), reason: 'cancelCount');
            expect(showCount, equals(0), reason: 'showCount');
          }

          widgetTester.clearAllMockMethodCallHandler();
        });

        testWidgets('withCurrentAct', (widgetTester) async {
          widgetTester.setMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications, []);

          final params = {
            memIdKey: withCurrentActMemId,
            notificationTypeKey: NotificationType.repeat.name
          };

          await scheduleCallback(0, params);

          widgetTester.clearAllMockMethodCallHandler();
        });
      });
    });
