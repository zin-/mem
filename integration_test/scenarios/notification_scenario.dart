import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/wrapper.dart';
import 'package:mem/values/durations.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testNotificationScenario();
}

const _scenarioName = "Notification scenario";

void testNotificationScenario() => group(
      ": $_scenarioName",
      () {
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

        group(
          ": scheduleCallback",
          () {
            for (var element in NotificationType.values) {
              testWidgets(
                ": ${element.name}.",
                (widgetTester) async {
                  setMockLocalNotifications(widgetTester);

                  final id = insertedMemId!;
                  final params = {
                    memIdKey: insertedMemId,
                    notificationTypeKey: element.name,
                  };

                  await scheduleCallback(id, params);
                },
              );
            }
          },
        );

        testWidgets(
          ": show MemDetailPage.",
          (widgetTester) async {
            final details = NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotification,
              id: memStartNotificationId(insertedMemId!),
              payload: json.encode({memIdKey: insertedMemId}),
            );

            await onDidReceiveNotificationResponse(details);

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

        group(': notification actions', () {
          testWidgets(
            ': done Mem.',
            (widgetTester) async {
              final details = NotificationResponse(
                notificationResponseType:
                    NotificationResponseType.selectedNotificationAction,
                id: memStartNotificationId(insertedMemId!),
                payload: json.encode({memIdKey: insertedMemId}),
                actionId:
                    NotificationClient().notificationActions.doneMemAction.id,
              );

              await onDidReceiveNotificationResponse(details);

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

          testWidgets(
            ': start Act.',
            (widgetTester) async {
              final details = NotificationResponse(
                notificationResponseType:
                    NotificationResponseType.selectedNotificationAction,
                id: memRepeatedNotificationId(insertedMemId!),
                payload: json.encode({memIdKey: insertedMemId}),
                actionId:
                    NotificationClient().notificationActions.startActAction.id,
              );

              await onDidReceiveNotificationResponse(details);

              await Future.delayed(
                waitSideEffectDuration,
                () async {
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
                },
              );
            },
          );

          group(": finish active Act", () {
            testWidgets(
              ': no active Act.',
              (widgetTester) async {
                final details = NotificationResponse(
                  notificationResponseType:
                      NotificationResponseType.selectedNotificationAction,
                  id: memRepeatedNotificationId(insertedMemId!),
                  payload: json.encode({memIdKey: insertedMemId}),
                  actionId: NotificationClient()
                      .notificationActions
                      .finishActiveActAction
                      .id,
                );

                await onDidReceiveNotificationResponse(details);

                await Future.delayed(
                  waitSideEffectDuration,
                  () async {
                    final acts = await dbA.select(defTableActs);
                    // final acts = await db.getTable(defTableActs.name).select();

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
                        isNotNull,
                        isFalse,
                        isNotNull,
                        isNotNull,
                        isNotNull,
                        isNull,
                        insertedMemId,
                      ],
                    );
                  },
                );
              },
            );

            group("2 active Acts.", () {
              late final int insertedActId;
              late final int insertedActId2;

              setUp(() async {
                insertedActId = await dbA.insert(defTableActs, {
                  defFkActsMemId.name: insertedMemId,
                  defColActsStart.name:
                      zeroDate.add(const Duration(minutes: 1)),
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
                ': 2 active Acts.',
                (widgetTester) async {
                  final details = NotificationResponse(
                    notificationResponseType:
                        NotificationResponseType.selectedNotificationAction,
                    id: memRepeatedNotificationId(insertedMemId!),
                    payload: json.encode({memIdKey: insertedMemId}),
                    actionId: NotificationClient()
                        .notificationActions
                        .finishActiveActAction
                        .id,
                  );

                  await onDidReceiveNotificationResponse(details);

                  await Future.delayed(
                    waitSideEffectDuration,
                    () async {
                      final acts = await dbA.select(defTableActs);

                      expect(acts.length, 2);
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
                          insertedActId,
                          isNotNull,
                          isNull,
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
                          isNotNull,
                          isFalse,
                          insertedActId2,
                          isNotNull,
                          isNotNull,
                          isNull,
                          insertedMemId,
                        ],
                      );
                    },
                  );
                },
              );
            });
          });

          group(": pause act", () {
            testWidgets(": no active act.", (widgetTester) async {
              final details = NotificationResponse(
                notificationResponseType:
                    NotificationResponseType.selectedNotificationAction,
                id: memRepeatedNotificationId(insertedMemId!),
                payload: json.encode({memIdKey: insertedMemId}),
                actionId: NotificationClient().notificationActions.pauseAct.id,
              );

              await onDidReceiveNotificationResponse(details);
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

              testWidgets(": no thrown.", (widgetTester) async {
                final details = NotificationResponse(
                  notificationResponseType:
                      NotificationResponseType.selectedNotificationAction,
                  id: memRepeatedNotificationId(insertedMemId!),
                  payload: json.encode({memIdKey: insertedMemId}),
                  actionId:
                      NotificationClient().notificationActions.pauseAct.id,
                );

                await onDidReceiveNotificationResponse(details);
              });
            });
          });
        });
      },
    );
