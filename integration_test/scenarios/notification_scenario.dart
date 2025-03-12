import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/framework/workmanager_wrapper.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';
import 'package:mem/notifications/notification_client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/notification_actions.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/schedule_client.dart';
import 'package:mem/values/constants.dart';
import 'package:mem/values/durations.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testNotificationScenario();
}

const _scenarioName = "Notification scenario";

void testNotificationScenario() => group(_scenarioName, () {
      LogService(
        level: Level.verbose,
        enableSimpleLog:
            const bool.fromEnvironment('CICD', defaultValue: false),
        enableErrorReport: false,
      );

      const insertedMemName = "$_scenarioName - mem name - inserted";

      late final DatabaseAccessor dbA;
      int? insertedMemId;

      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });
      setUp(() async {
        await clearAllTestDatabaseRows(databaseDefinition);

        insertedMemId = await dbA.insert(defTableMems, {
          defColMemsName.name: insertedMemName,
          defColMemsDoneAt.name: null,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableMemNotifications, {
          defFkMemNotificationsMemId.name: insertedMemId,
          defColMemNotificationsTime.name: 0,
          defColMemNotificationsType.name: MemNotificationType.repeat.name,
          defColMemNotificationsMessage.name:
              "$_scenarioName - inserted - mem notification message - repeat",
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableMemNotifications, {
          defFkMemNotificationsMemId.name: insertedMemId,
          defColMemNotificationsTime.name: 1,
          defColMemNotificationsType.name:
              MemNotificationType.afterActStarted.name,
          defColMemNotificationsMessage.name:
              "$_scenarioName - inserted - mem notification message - after act started",
          defColCreatedAt.name: zeroDate,
        });
      });

      group("ScheduleCallback", () {
        for (var element in NotificationType.values.where(
          (e) => e != NotificationType.notifyAfterInactivity,
        )) {
          testWidgets(
            "${element.name}.",
            (widgetTester) async {
              widgetTester.ignoreMockMethodCallHandler(
                  MethodChannelMock.flutterLocalNotifications);
              int requestPermissionsCount = 0;
              widgetTester.setMockMethodCallHandler(MethodChannelMock.mem, [
                (m) async {
                  expect(m.method, requestPermissions);
                  requestPermissionsCount++;
                  throw MissingPluginException();
                },
                (m) => fail("Too many call."),
              ]);
              int checkPermissionStatusCount = 0;
              widgetTester.setMockMethodCallHandler(
                  MethodChannelMock.permissionHandler, [
                (m) async {
                  expect(m.method, 'checkPermissionStatus');
                  checkPermissionStatusCount++;
                  return 1;
                },
                (m) => fail("Too many call."),
              ]);

              final id = insertedMemId!;
              final params = {
                memIdKey: insertedMemId,
                notificationTypeKey: element.name,
              };

              await scheduleCallback(id, params);

              expect(
                requestPermissionsCount,
                equals(1),
                reason: 'requestPermissionsCount',
              );
              expect(
                checkPermissionStatusCount,
                equals(1),
                reason: 'checkPermissionStatusCount',
              );
            },
          );
        }

        testWidgets("${NotificationType.notifyAfterInactivity.name}.",
            (widgetTester) async {
          final notificationType = NotificationType.notifyAfterInactivity;

          widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications);
          int requestPermissionsCount = 0;
          widgetTester.setMockMethodCallHandler(MethodChannelMock.mem, [
            (m) async {
              expect(m.method, requestPermissions);
              requestPermissionsCount++;
              throw MissingPluginException();
            }
          ]);
          int checkPermissionStatusCount = 0;
          widgetTester
              .setMockMethodCallHandler(MethodChannelMock.permissionHandler, [
            (m) async {
              expect(m.method, 'checkPermissionStatus');
              checkPermissionStatusCount++;
              return 1;
            },
            (m) => fail("Too many call."),
          ]);

          final params = {
            notificationTypeKey: notificationType.name,
          };

          await scheduleCallback(
            notificationType.buildNotificationId(),
            params,
          );

          expect(
            requestPermissionsCount,
            equals(1),
            reason: 'requestPermissionsCount',
          );
          expect(
            checkPermissionStatusCount,
            equals(1),
            reason: 'checkPermissionStatusCount',
          );
        });

        testWidgets("PlatformException.", (widgetTester) async {
          final notificationType = NotificationType.notifyAfterInactivity;

          widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications);
          int requestPermissionsCount = 0;
          widgetTester.setMockMethodCallHandler(MethodChannelMock.mem, [
            (m) async {
              expect(m.method, requestPermissions);
              requestPermissionsCount++;
              throw PlatformException(code: 'on test code.');
            }
          ]);
          int checkPermissionStatusCount = 0;
          widgetTester
              .setMockMethodCallHandler(MethodChannelMock.permissionHandler, [
            (m) async {
              expect(m.method, 'checkPermissionStatus');
              checkPermissionStatusCount++;
              return 1;
            },
            (m) => fail("Too many call."),
          ]);

          final params = {
            notificationTypeKey: notificationType.name,
          };

          await scheduleCallback(
            notificationType.buildNotificationId(),
            params,
          );

          expect(
            requestPermissionsCount,
            equals(1),
            reason: 'requestPermissionsCount',
          );
          expect(
            checkPermissionStatusCount,
            equals(0),
            reason: 'checkPermissionStatusCount',
          );
        });
      });

      testWidgets(
        ": show MemDetailPage.",
        (widgetTester) async {
          final details = NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: memStartNotificationId(insertedMemId!),
            payload: json.encode({memIdKey: insertedMemId}),
          );

          await onNotificationResponseReceived(details);

          await Future.delayed(
            defaultTransitionDuration,
            () async {
              await widgetTester.pumpAndSettle(defaultTransitionDuration);

              expect(
                (widgetTester.widget(memNameOnDetailPageFinder)
                        as TextFormField)
                    .initialValue,
                insertedMemName,
              );
            },
          );
        },
      );

      group('Notification actions', () {
        testWidgets(
          ': done Mem.',
          (widgetTester) async {
            final details = NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotificationAction,
              id: memStartNotificationId(insertedMemId!),
              payload: json.encode({memIdKey: insertedMemId}),
              actionId: buildNotificationActions()
                  .singleWhere((e) => e.id == doneMemNotificationActionId)
                  .id,
            );

            await onNotificationResponseReceived(details);

            await Future.delayed(
              waitSideEffectDuration,
              () async {
                final mems = await dbA.select(defTableMems);
                // final mems = await db.getTable(defTableMems.name).select();

                expect(mems.length, 1);
                expect(
                  [
                    mems[0][defColMemsName.name],
                    mems[0][defColMemsDoneAt.name],
                    mems[0][defColMemsStartOn.name],
                    mems[0][defColMemsStartAt.name],
                    mems[0][defColMemsEndOn.name],
                    mems[0][defColMemsEndAt.name],
                    mems[0][defPkId.name],
                    mems[0][defColCreatedAt.name],
                    mems[0][defColUpdatedAt.name],
                    mems[0][defColArchivedAt.name],
                  ],
                  [
                    insertedMemName,
                    isNotNull,
                    isNull,
                    isNull,
                    isNull,
                    isNull,
                    insertedMemId,
                    isNotNull,
                    isNotNull,
                    isNull,
                  ],
                );
              },
            );
          },
        );

        testWidgets('Start Act.', (widgetTester) async {
          widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
          widgetTester.ignoreMockMethodCallHandler(
            MethodChannelMock.permissionHandler,
          );
          widgetTester.ignoreMockMethodCallHandler(
            MethodChannelMock.workmanagerForeground,
          );

          final details = NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            id: memRepeatedNotificationId(insertedMemId!),
            payload: json.encode({memIdKey: insertedMemId}),
            actionId: buildNotificationActions()
                .singleWhere((e) => e.id == startActNotificationActionId)
                .id,
          );

          await onNotificationResponseReceived(details);

          await Future.delayed(waitSideEffectDuration, () async {
            final acts = await dbA.select(defTableActs);

            expect(acts.length, 1);
            expect(
              [
                acts[0][defColActsStart.name],
                acts[0][defColActsStartIsAllDay.name],
                acts[0][defColActsEnd.name],
                acts[0][defColActsEndIsAllDay.name],
                acts[0][defPkId.name],
                acts[0][defColCreatedAt.name],
                acts[0][defColUpdatedAt.name],
                acts[0][defColArchivedAt.name],
                acts[0][defFkActsMemId.name],
              ],
              [
                isNotNull,
                isFalse,
                isNull,
                isNull,
                isNotNull,
                isNotNull,
                isNull,
                isNull,
                insertedMemId,
              ],
            );
          });
        });

        group(": finish active Act", () {
          testWidgets(
            ": no active Act.",
            (widgetTester) async {
              final details = NotificationResponse(
                notificationResponseType:
                    NotificationResponseType.selectedNotificationAction,
                id: memRepeatedNotificationId(insertedMemId!),
                payload: json.encode({memIdKey: insertedMemId}),
                actionId: buildNotificationActions()
                    .singleWhere(
                        (e) => e.id == finishActiveActNotificationActionId)
                    .id,
              );

              await onNotificationResponseReceived(details);

              final acts = await dbA.select(defTableActs);

              expect(acts, hasLength(1));
              expect(
                [
                  acts[0][defColActsStart.name],
                  acts[0][defColActsStartIsAllDay.name],
                  acts[0][defColActsEnd.name],
                  acts[0][defColActsEndIsAllDay.name],
                  acts[0][defPkId.name],
                  acts[0][defColCreatedAt.name],
                  acts[0][defColUpdatedAt.name],
                  acts[0][defColArchivedAt.name],
                  acts[0][defFkActsMemId.name],
                ],
                [
                  isNotNull,
                  isFalse,
                  isNotNull,
                  isFalse,
                  isNotNull,
                  isNotNull,
                  isNull,
                  isNull,
                  insertedMemId,
                ],
              );
            },
          );

          group("2 active Acts.", () {
            late final int insertedActId1;
            late final int insertedActId2;

            setUp(() async {
              insertedActId1 = await dbA.insert(defTableActs, {
                defFkActsMemId.name: insertedMemId,
                defColActsStart.name: zeroDate.add(const Duration(minutes: 1)),
                defColActsStartIsAllDay.name: 0,
                defColCreatedAt.name: zeroDate,
              });
              insertedActId2 = await dbA.insert(defTableActs, {
                defFkActsMemId.name: insertedMemId,
                defColActsStart.name: zeroDate,
                defColActsStartIsAllDay.name: 0,
                defColCreatedAt.name: zeroDate,
              });
            });

            testWidgets(
              ': test.',
              (widgetTester) async {
                final details = NotificationResponse(
                  notificationResponseType:
                      NotificationResponseType.selectedNotificationAction,
                  id: memRepeatedNotificationId(insertedMemId!),
                  payload: json.encode({memIdKey: insertedMemId}),
                  actionId: buildNotificationActions()
                      .singleWhere(
                          (e) => e.id == finishActiveActNotificationActionId)
                      .id,
                );

                await onNotificationResponseReceived(details);

                final acts = await dbA.select(defTableActs);

                expect(acts, hasLength(2));
                expect(
                  [
                    acts[0][defColActsStart.name],
                    acts[0][defColActsStartIsAllDay.name],
                    acts[0][defColActsEnd.name],
                    acts[0][defColActsEndIsAllDay.name],
                    acts[0][defPkId.name],
                    acts[0][defColCreatedAt.name],
                    acts[0][defColUpdatedAt.name],
                    acts[0][defColArchivedAt.name],
                    acts[0][defFkActsMemId.name],
                  ],
                  [
                    isNotNull,
                    isFalse,
                    isNotNull,
                    isFalse,
                    insertedActId1,
                    isNotNull,
                    isNotNull,
                    isNull,
                    insertedMemId,
                  ],
                );
                expect(
                  [
                    acts[1][defColActsStart.name],
                    acts[1][defColActsStartIsAllDay.name],
                    acts[1][defColActsEnd.name],
                    acts[1][defColActsEndIsAllDay.name],
                    acts[1][defPkId.name],
                    acts[1][defColCreatedAt.name],
                    acts[1][defColUpdatedAt.name],
                    acts[1][defColArchivedAt.name],
                    acts[1][defFkActsMemId.name],
                  ],
                  [
                    isNotNull,
                    isFalse,
                    isNull,
                    isNull,
                    insertedActId2,
                    isNotNull,
                    isNull,
                    isNull,
                    insertedMemId,
                  ],
                );
              },
            );
          });
        });

        group("Pause act", () {
          testWidgets("No active act.", (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(
                MethodChannelMock.flutterLocalNotifications);
            widgetTester.ignoreMockMethodCallHandler(
                MethodChannelMock.workmanagerForeground);
            int requestPermissionsCount = 0;
            widgetTester.setMockMethodCallHandler(
              MethodChannelMock.mem,
              [
                ...List.generate(
                  2,
                  (i) => (m) async {
                    expect(m.method, requestPermissions);
                    requestPermissionsCount++;
                    return true;
                  },
                ),
                (m) => fail("Too many call."),
              ],
            );

            final details = NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotificationAction,
              id: memRepeatedNotificationId(insertedMemId!),
              payload: json.encode({memIdKey: insertedMemId}),
              actionId: buildNotificationActions()
                  .singleWhere((e) => e.id == pauseActNotificationActionId)
                  .id,
            );

            await onNotificationResponseReceived(details);

            expect(
              requestPermissionsCount,
              equals(2),
              reason: 'requestPermissionsCount',
            );
          });

          group(": 2 active acts", () {
            setUp(() async {
              dbA.insert(defTableActs, {
                defFkActsMemId.name: insertedMemId,
                defColActsStart.name: zeroDate,
                defColActsStartIsAllDay.name: false,
                defColCreatedAt.name: zeroDate,
              });
              dbA.insert(defTableActs, {
                defFkActsMemId.name: insertedMemId,
                defColActsStart.name: zeroDate,
                defColActsStartIsAllDay.name: false,
                defColCreatedAt.name: zeroDate,
              });
            });

            testWidgets("No thrown.", (widgetTester) async {
              widgetTester.ignoreMockMethodCallHandler(
                  MethodChannelMock.flutterLocalNotifications);
              int requestPermissionsCount = 0;
              widgetTester.setMockMethodCallHandler(
                MethodChannelMock.mem,
                [
                  ...List.generate(
                    2,
                    (i) => (m) async {
                      expect(m.method, requestPermissions);
                      requestPermissionsCount++;
                      return true;
                    },
                  ),
                  (m) => fail("Too many call."),
                ],
              );

              final details = NotificationResponse(
                notificationResponseType:
                    NotificationResponseType.selectedNotificationAction,
                id: memRepeatedNotificationId(insertedMemId!),
                payload: json.encode({memIdKey: insertedMemId}),
                actionId: buildNotificationActions()
                    .singleWhere((e) => e.id == pauseActNotificationActionId)
                    .id,
              );

              await onNotificationResponseReceived(details);

              expect(
                requestPermissionsCount,
                equals(2),
                reason: 'requestPermissionsCount',
              );
            });
          });
        });
      });

      testWidgets("WorkmanagerCallbackDispatcher", (widgetTester) async {
        await WorkmanagerWrapper(
          callbackDispatcher: workmanagerCallbackDispatcher,
        ).registerOneOffTask(
          Task.notify,
          DateTime.now(),
          0,
          {
            notificationTypeKey: NotificationType.startMem.name,
            memIdKey: 0,
          },
        );

        await Future.delayed(Duration(seconds: 5));

        expect(true, isTrue);
      });
    });
