import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/definition.dart';
import 'package:mem/database/table_definitions/acts.dart';
import 'package:mem/database/table_definitions/base.dart';
import 'package:mem/database/table_definitions/mems.dart';
import 'package:mem/framework/database/database.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/wrapper.dart';
import 'package:mem/values/durations.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testNotificationScenario();
}

const _scenarioName = "Notification scenario";

void testNotificationScenario() => group(": $_scenarioName", () {
      const insertedMemName = "$_scenarioName - mem name - inserted";

      late final Database db;
      int? insertedMemId;

      setUpAll(() async {
        db = await DatabaseManager(onTest: true).open(databaseDefinition);
      });
      setUp(() async {
        await resetDatabase(db);

        insertedMemId = await db.getTable(memTableDefinition.name).insert({
          defMemName.name: insertedMemName,
          defMemDoneAt.name: null,
          createdAtColDef.name: DateTime(0),
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
              actionId: NotificationClient().doneMemAction.id,
            );

            await onDidReceiveNotificationResponse(details);

            await Future.delayed(
              waitSideEffectDuration,
              () async {
                final mems =
                    await db.getTable(memTableDefinition.name).select();

                expect(mems.length, 1);
                expect(
                  [
                    mems[0][defMemName.name],
                    mems[0][defMemDoneAt.name],
                    mems[0][defMemStartOn.name],
                    mems[0][defMemStartAt.name],
                    mems[0][defMemEndOn.name],
                    mems[0][defMemEndAt.name],
                    mems[0][idPKDef.name],
                    mems[0][createdAtColDef.name],
                    mems[0][updatedAtColDef.name],
                    mems[0][archivedAtColDef.name],
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
              actionId: NotificationClient().startActAction.id,
            );

            await onDidReceiveNotificationResponse(details);

            await Future.delayed(
              waitSideEffectDuration,
              () async {
                final acts =
                    await db.getTable(actTableDefinition.name).select();

                expect(acts.length, 1);
                expect(
                  [
                    acts[0][defActStart.name],
                    acts[0][defActStartIsAllDay.name],
                    acts[0][defActEnd.name],
                    acts[0][defActEndIsAllDay.name],
                    acts[0][idPKDef.name],
                    acts[0][createdAtColDef.name],
                    acts[0][updatedAtColDef.name],
                    acts[0][archivedAtColDef.name],
                    acts[0][fkDefMemId.name],
                  ],
                  [
                    isNotNull,
                    0,
                    isNull,
                    0,
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
                actionId: NotificationClient().finishActiveActAction.id,
              );

              await onDidReceiveNotificationResponse(details);

              await Future.delayed(
                waitSideEffectDuration,
                () async {
                  final acts =
                      await db.getTable(actTableDefinition.name).select();

                  expect(acts.length, 1);
                  expect(
                    [
                      acts[0][defActStart.name],
                      acts[0][defActStartIsAllDay.name],
                      acts[0][defActEnd.name],
                      acts[0][defActEndIsAllDay.name],
                      acts[0][idPKDef.name],
                      acts[0][createdAtColDef.name],
                      acts[0][updatedAtColDef.name],
                      acts[0][archivedAtColDef.name],
                      acts[0][fkDefMemId.name],
                    ],
                    [
                      isNotNull,
                      0,
                      isNotNull,
                      0,
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
              final actsTable = db.getTable(actTableDefinition.name);

              insertedActId = await actsTable.insert({
                fkDefMemId.name: insertedMemId,
                defActStart.name: zeroDate.add(const Duration(minutes: 1)),
                defActStartIsAllDay.name: 0,
                createdAtColDef.name: zeroDate,
              });
              insertedActId2 = await actsTable.insert({
                fkDefMemId.name: insertedMemId,
                defActStart.name: zeroDate,
                defActStartIsAllDay.name: 0,
                createdAtColDef.name: zeroDate,
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
                  actionId: NotificationClient().finishActiveActAction.id,
                );

                await onDidReceiveNotificationResponse(details);

                await Future.delayed(
                  waitSideEffectDuration,
                  () async {
                    final acts =
                        await db.getTable(actTableDefinition.name).select();

                    expect(acts.length, 2);
                    expect(
                      [
                        acts[0][defActStart.name],
                        acts[0][defActStartIsAllDay.name],
                        acts[0][defActEnd.name],
                        acts[0][defActEndIsAllDay.name],
                        acts[0][idPKDef.name],
                        acts[0][createdAtColDef.name],
                        acts[0][updatedAtColDef.name],
                        acts[0][archivedAtColDef.name],
                        acts[0][fkDefMemId.name],
                      ],
                      [
                        isNotNull,
                        0,
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
                        acts[1][defActStart.name],
                        acts[1][defActStartIsAllDay.name],
                        acts[1][defActEnd.name],
                        acts[1][defActEndIsAllDay.name],
                        acts[1][idPKDef.name],
                        acts[1][createdAtColDef.name],
                        acts[1][updatedAtColDef.name],
                        acts[1][archivedAtColDef.name],
                        acts[1][fkDefMemId.name],
                      ],
                      [
                        isNotNull,
                        0,
                        isNotNull,
                        0,
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
      });
    });
