import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/acts/act_entity.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/client.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/seconds_of_time_picker.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/mems/mem_notification_entity.dart';
import 'package:mem/mems/mem_notification_repository.dart';
import 'package:mem/mems/mem_repository.dart';
import 'package:mem/notifications/notification_client.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/settings/preference/client.dart';
import 'package:mem/settings/preference/repository.dart';
import 'package:mem/settings/preference/preference.dart';
import 'package:mem/settings/preference/keys.dart';
import 'package:settings_ui/settings_ui.dart';

import '../helpers.dart';

const _scenarioName = "Settings test";

void main() => group(
      _scenarioName,
      () {
        LogService(
          level: Level.verbose,
          enableSimpleLog:
              const bool.fromEnvironment('CICD', defaultValue: false),
        );

        const numberOfMem = 100;
        const insertedMemName = '$_scenarioName: inserted - mem name';

        late final DatabaseAccessor dbA;

        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });

        setUp(() async {
          NotificationClient.resetSingleton();

          await clearAllTestDatabaseRows(databaseDefinition);
        });

        testWidgets(
          'show page.',
          (widgetTester) async {
            widgetTester.clearAllMockMethodCallHandler();

            await runApplication();
            await widgetTester.pumpAndSettle();

            expect(find.byType(AppBar), findsOneWidget);

            await widgetTester.tap(drawerIconFinder);
            await widgetTester.pumpAndSettle();

            expect(find.byIcon(Icons.settings), findsOneWidget);
            await widgetTester.tap(find.text(l10n.settingsPageTitle));
            await widgetTester.pumpAndSettle();

            expect(find.text(l10n.settingsPageTitle), findsOneWidget);
            expect(find.byIcon(Icons.start), findsOneWidget);
            expect(find.text(l10n.startOfDayLabel), findsOneWidget);
            expect(find.byIcon(Icons.backup), findsOneWidget);
            expect(find.text(l10n.backupLabel), findsOneWidget);
            expect(find.byIcon(Icons.backup), findsOneWidget);
            expect(find.text(l10n.resetNotificationLabel), findsOneWidget);
          },
        );

        group(
          'Start of day',
          () {
            setUp(() async {
              await PreferenceRepository().discard(startOfDayKey);
            });

            testWidgets(
              ': pick.',
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(drawerIconFinder);
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(l10n.settingsPageTitle));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(l10n.startOfDayLabel));
                await widgetTester.pumpAndSettle();

                final rect =
                    widgetTester.getRect(find.byKey(Key('time-picker-dial')));
                final tapPosition = Offset(
                  rect.left + rect.width / 2,
                  rect.top + rect.height / 2,
                );
                await widgetTester.tapAt(tapPosition);
                await widgetTester.tap(okFinder);
                await widgetTester.pumpAndSettle();

                expect(
                  widgetTester
                      .widget<Text>(find
                          .descendant(
                            of: find.byType(SettingsTile),
                            matching: find.byType(Text),
                          )
                          .at(1))
                      .data,
                  "6:00 AM",
                );
                expect(
                  (await PreferenceRepository().shipByKey(startOfDayKey)).value,
                  TimeOfDay(hour: 6, minute: 0),
                );
              },
            );

            group(
              'With saved',
              () {
                final now = DateTime.now();
                setUp(() async {
                  await PreferenceRepository().receive(PreferenceEntity(
                      startOfDayKey, TimeOfDay.fromDateTime(now)));

                  final savedMem = await MemRepositoryV2().receive(MemEntityV2(
                      Mem("$insertedMemName - Start of day", null, null)));
                  await MemNotificationRepositoryV2().receive(
                    MemNotificationEntityV2(
                      MemNotification.initialByType(
                        savedMem.id,
                        MemNotificationType.repeat,
                        time: () => 60,
                      ),
                    ),
                  );
                  final savedMem2 = await MemRepositoryV2().receive(MemEntityV2(
                      Mem("$insertedMemName - Start of day - 2", null, null)));
                  await MemNotificationRepositoryV2().receive(
                    MemNotificationEntityV2(
                      MemNotification.initialByType(
                        savedMem2.id,
                        MemNotificationType.repeat,
                        time: () => 60 * 60 * 24 - 60,
                      ),
                    ),
                  );
                });

                testWidgets('show saved.', (widgetTester) async {
                  await runApplication();
                  await widgetTester.pumpAndSettle();

                  await widgetTester.tap(drawerIconFinder);
                  await widgetTester.pumpAndSettle();
                  await widgetTester.tap(find.text(l10n.settingsPageTitle));
                  await widgetTester.pumpAndSettle();

                  expect(
                      widgetTester
                          .widget<Text>(find
                              .descendant(
                                  of: find.byType(SettingsTile),
                                  matching: find.byType(Text))
                              .at(1))
                          .data,
                      timeText(now));
                });

                testWidgets(
                  "Before start of tomorrow is today's habit.",
                  (widgetTester) async {
                    await runApplication();
                    await widgetTester.pumpAndSettle(Duration(seconds: 10));

                    final texts =
                        widgetTester.widgetList<Text>(find.byType(Text));
                    expect(texts.elementAt(0).data, equals(dateText(now)));
                    expect(texts.elementAt(3).data,
                        equals(dateText(now.add(Duration(days: 1)))));
                  },
                );
              },
            );
          },
        );

        group("Notify after inactivity", () {
          setUp(
            () async {
              await PreferenceRepository().discard(notifyAfterInactivity);
            },
          );

          testWidgets(
            "Show.",
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(drawerIconFinder);
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(find.text(l10n.settingsPageTitle));
              await widgetTester.pumpAndSettle();

              final texts = widgetTester.widgetList<Text>(find.byType(Text));
              expect(
                texts.elementAt(2).data,
                equals(l10n.notifyAfterInactivityLabel),
              );
            },
          );

          testWidgets(
            "Save.",
            (widgetTester) async {
              widgetTester.clearAllMockMethodCallHandler();

              int alarmServiceStartCount = 0;
              int alarmOneShotAtCount = 0;
              widgetTester.setMockMethodCallHandler(
                MethodChannelMock.androidAlarmManager,
                [
                  (m) async {
                    expect(m.method, equals('AlarmService.start'));
                    alarmServiceStartCount++;
                    return true;
                  },
                  (m) async {
                    expect(m.method, equals('Alarm.oneShotAt'));
                    alarmOneShotAtCount++;
                    return true;
                  },
                ],
              );

              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(drawerIconFinder);
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(find.text(l10n.settingsPageTitle));
              await widgetTester.pumpAndSettle();

              const secondsOfHour = 3600;
              final texts = widgetTester.widgetList<Text>(find.byType(Text));
              expect(
                texts.elementAt(3).data,
                isNot(equals(formatSecondsOfTime(secondsOfHour))),
              );

              await widgetTester
                  .tap(find.text(l10n.notifyAfterInactivityLabel));
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(find.text(l10n.okAction));
              await widgetTester.pumpAndSettle();

              final texts2 = widgetTester.widgetList<Text>(find.byType(Text));
              expect(
                texts2.elementAt(3).data,
                equals(formatSecondsOfTime(secondsOfHour)),
              );

              expect(
                await PreferenceRepository()
                    .shipByKey(notifyAfterInactivity)
                    .then(
                      (v) => v.value,
                    ),
                equals(secondsOfHour),
              );

              expect(
                alarmServiceStartCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                ),
                reason: 'alarmServiceStartCount',
              );
              expect(
                alarmOneShotAtCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                ),
                reason: 'alarmOneShotAtCount',
              );
            },
          );

          group("With saved", () {
            setUp(
              () async {
                await PreferenceRepository()
                    .receive(PreferenceEntity(notifyAfterInactivity, 3600));

                PreferenceClient.resetSingleton();
              },
            );

            testWidgets(
              "Remove.",
              (widgetTester) async {
                widgetTester.clearAllMockMethodCallHandler();

                int alarmServiceStartCount = 0;
                int alarmCancelCount = 0;
                widgetTester.setMockMethodCallHandler(
                  MethodChannelMock.androidAlarmManager,
                  [
                    (m) async {
                      expect(m.method, equals('AlarmService.start'));
                      alarmServiceStartCount++;
                      return true;
                    },
                    (m) async {
                      expect(m.method, equals('Alarm.cancel'));
                      alarmCancelCount++;
                      return true;
                    },
                    (m) async {
                      expect(m.method, equals('Alarm.oneShotAt'));
                      return true;
                    },
                  ],
                );

                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(drawerIconFinder);
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(l10n.settingsPageTitle));
                await widgetTester.pumpAndSettle();
                await widgetTester
                    .tap(find.text(l10n.notifyAfterInactivityLabel));
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(l10n.cancelAction));
                await widgetTester.pumpAndSettle();

                expect(
                  await PreferenceRepository()
                      .shipByKey(notifyAfterInactivity)
                      .then(
                        (v) => v.value,
                      ),
                  isNull,
                );

                expect(
                  alarmServiceStartCount,
                  equals(
                    defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                  ),
                  reason: 'alarmServiceStartCount',
                );
                expect(
                  alarmCancelCount,
                  equals(
                    defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                  ),
                  reason: 'alarmCancelCount',
                );
              },
            );

            group(
              "With habit operation",
              () {
                setUp(
                  () async {
                    ActsClient.resetSingleton();
                    NotificationClient.resetSingleton();

                    final savedMemWithNoAct = await MemRepositoryV2().receive(
                        MemEntityV2(Mem(
                            "$_scenarioName - With habit operation - with no act",
                            null,
                            null)));
                    await MemNotificationRepositoryV2().receive(
                        MemNotificationEntityV2(MemNotification(
                            savedMemWithNoAct.id,
                            MemNotificationType.afterActStarted,
                            1,
                            "with no act")));

                    final savedMemWithActiveAct = await MemRepositoryV2()
                        .receive(MemEntityV2(Mem(
                            "$_scenarioName - With habit operation - with active act",
                            null,
                            null)));
                    await MemNotificationRepositoryV2().receive(
                        MemNotificationEntityV2(MemNotification(
                            savedMemWithActiveAct.id,
                            MemNotificationType.afterActStarted,
                            1,
                            "with active act")));
                    await ActRepository().receive(ActEntity(
                        Act.by(savedMemWithActiveAct.id, DateAndTime.now())));
                  },
                );

                testWidgets("Cancel when start act.", (widgetTester) async {
                  widgetTester.clearAllMockMethodCallHandler();
                  widgetTester.ignoreMockMethodCallHandler(
                      MethodChannelMock.permissionHandler);
                  widgetTester.ignoreMockMethodCallHandler(
                      MethodChannelMock.flutterLocalNotifications);

                  int alarmServiceStartCount = 0;
                  int alarmCancelCount = 0;
                  widgetTester.setMockMethodCallHandler(
                    MethodChannelMock.androidAlarmManager,
                    [
                      (m) async {
                        expect(m.method, equals('AlarmService.start'));
                        alarmServiceStartCount++;
                        return true;
                      },
                      (m) async {
                        expect(m.method, equals('Alarm.cancel'));
                        alarmCancelCount++;
                        return true;
                      },
                    ],
                  );

                  await runApplication();
                  await widgetTester.pumpAndSettle();
                  await widgetTester.tap(startIconFinder);
                  await widgetTester.pumpAndSettle(waitLongSideEffectDuration);

                  await expectLater(
                    alarmServiceStartCount,
                    equals(
                      defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                    ),
                    reason: 'alarmServiceStartCount',
                  );
                  expect(
                    alarmCancelCount,
                    equals(
                      defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                    ),
                    reason: 'alarmCancelCount',
                  );
                });

                testWidgets("Set when finish act.", (widgetTester) async {
                  widgetTester.clearAllMockMethodCallHandler();
                  widgetTester.ignoreMockMethodCallHandler(
                      MethodChannelMock.permissionHandler);
                  widgetTester.ignoreMockMethodCallHandler(
                      MethodChannelMock.flutterLocalNotifications);

                  int alarmServiceStartCount = 0;
                  int alarmCancelCount = 0;
                  int alarmOneShotAtCount = 0;
                  widgetTester.setMockMethodCallHandler(
                    MethodChannelMock.androidAlarmManager,
                    [
                      (m) async {
                        expect(m.method, equals('AlarmService.start'));
                        alarmServiceStartCount++;
                        return true;
                      },
                      (m) async {
                        expect(m.method, equals('Alarm.cancel'));
                        alarmCancelCount++;
                        return true;
                      },
                      (m) async {
                        expect(m.method, equals('Alarm.oneShotAt'));
                        alarmOneShotAtCount++;
                        return true;
                      },
                    ],
                  );

                  await runApplication();
                  await widgetTester.pumpAndSettle();
                  await widgetTester.tap(stopIconFinder);
                  await widgetTester.pumpAndSettle();

                  expect(
                    alarmServiceStartCount,
                    equals(
                      defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                    ),
                    reason: 'alarmServiceStartCount',
                  );
                  expect(
                    alarmCancelCount,
                    equals(
                      defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                    ),
                    reason: 'alarmCancelCount',
                  );
                  expect(
                    alarmOneShotAtCount,
                    equals(
                      defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                    ),
                    reason: 'alarmOneShotAtCount',
                  );
                });

                testWidgets("Set when pause act.", (widgetTester) async {
                  widgetTester.clearAllMockMethodCallHandler();
                  widgetTester.ignoreMockMethodCallHandler(
                      MethodChannelMock.permissionHandler);
                  widgetTester.ignoreMockMethodCallHandler(
                      MethodChannelMock.flutterLocalNotifications);

                  int alarmServiceStartCount = 0;
                  int alarmCancelCount = 0;
                  int alarmOneShotAtCount = 0;
                  widgetTester.setMockMethodCallHandler(
                    MethodChannelMock.androidAlarmManager,
                    [
                      (m) async {
                        expect(m.method, equals('AlarmService.start'));
                        alarmServiceStartCount++;
                        return true;
                      },
                      (m) async {
                        expect(m.method, equals('Alarm.cancel'));
                        alarmCancelCount++;
                        return true;
                      },
                      (m) async {
                        expect(m.method, equals('Alarm.cancel'));
                        alarmCancelCount++;
                        return true;
                      },
                      (m) async {
                        expect(m.method, equals('Alarm.cancel'));
                        alarmCancelCount++;
                        return true;
                      },
                      (m) async {
                        expect(m.method, equals('Alarm.cancel'));
                        alarmCancelCount++;
                        return true;
                      },
                      (m) async {
                        expect(m.method, equals('Alarm.oneShotAt'));
                        alarmOneShotAtCount++;
                        return true;
                      },
                    ],
                  );

                  await runApplication();
                  await widgetTester.pumpAndSettle();
                  await widgetTester.tap(pauseIconFinder);
                  await widgetTester.pumpAndSettle(waitLongSideEffectDuration);

                  expect(
                    alarmServiceStartCount,
                    equals(
                      defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                    ),
                    reason: 'alarmServiceStartCount',
                  );
                  expect(
                    alarmCancelCount,
                    equals(
                      defaultTargetPlatform == TargetPlatform.android ? 4 : 0,
                    ),
                    reason: 'alarmCancelCount',
                  );
                  expect(
                    alarmOneShotAtCount,
                    equals(
                      defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                    ),
                    reason: 'alarmOneShotAtCount',
                  );
                });
              },
            );
          });
        });

        group(
          "Reset Notification",
          () {
            final insertedMemIds = List<int>.empty(growable: true);

            setUp(
              () async {
                for (var i = 0; i < numberOfMem; i++) {
                  insertedMemIds.add(
                    await dbA.insert(
                      defTableMems,
                      {
                        defColMemsName.name: "$insertedMemName: $i",
                        defColCreatedAt.name: zeroDate,
                      },
                    ),
                  );
                }
              },
            );

            testWidgets(
              "Execute.",
              (widgetTester) async {
                widgetTester.ignoreMockMethodCallHandler(
                    MethodChannelMock.permissionHandler);
                int alarmServiceStartCount = 0;
                int alarmCancelCount = 0;
                final cancelIds = insertedMemIds
                    .map(
                      (e) => [
                        memStartNotificationId(e),
                        memEndNotificationId(e),
                        memRepeatedNotificationId(e),
                      ],
                    )
                    .flattened;
                widgetTester.setMockMethodCallHandler(
                    MethodChannelMock.androidAlarmManager, [
                  (m) async {
                    expect(m.method, equals('AlarmService.start'));
                    alarmServiceStartCount++;
                    return true;
                  },
                  ...cancelIds.map((e) => (m) async {
                        expect(m.method, equals('Alarm.cancel'));
                        alarmCancelCount++;
                        return false;
                      }),
                ]);

                int initializeCount = 0;
                int getNotificationAppLaunchDetailsCount = 0;
                int cancelAllCount = 0;
                int deleteNotificationChannelCount = 0;
                widgetTester.setMockMethodCallHandler(
                    MethodChannelMock.flutterLocalNotifications, [
                  (m) async {
                    expect(m.method, equals('initialize'));
                    initializeCount++;
                    return true;
                  },
                  (m) async {
                    expect(m.method, equals('getNotificationAppLaunchDetails'));
                    getNotificationAppLaunchDetailsCount++;
                    return null;
                  },
                  (m) async {
                    expect(m.method, equals('cancelAll'));
                    cancelAllCount++;
                    return null;
                  },
                  ...NotificationType.values.map(
                    (e) => (m) async {
                      expect(m.method, equals('deleteNotificationChannel'));
                      deleteNotificationChannelCount++;
                      return null;
                    },
                  ),
                ]);

                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(drawerIconFinder);
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(l10n.settingsPageTitle));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(l10n.resetNotificationLabel));
                await widgetTester.pump();

                expect(find.byType(CircularProgressIndicator), findsOneWidget);

                var indicator = widgetTester
                    .elementList(find.byType(CircularProgressIndicator));
                while (indicator.length == 1) {
                  await widgetTester.pump();
                  indicator = widgetTester
                      .elementList(find.byType(CircularProgressIndicator));
                }

                expect(find.byType(CircularProgressIndicator), findsNothing);
                expect(
                    find.text(l10n.completeResetNotification), findsOneWidget);

                if (defaultTargetPlatform == TargetPlatform.android) {
                  expect(alarmServiceStartCount, equals(1),
                      reason: 'alarmServiceStartCount');
                  expect(alarmCancelCount, equals(300),
                      reason: 'alarmCancelCount');
                  expect(initializeCount, equals(1), reason: 'initializeCount');
                  expect(getNotificationAppLaunchDetailsCount, equals(1),
                      reason: 'getNotificationAppLaunchDetailsCount');
                  expect(cancelAllCount, equals(1), reason: 'cancelAllCount');
                  expect(deleteNotificationChannelCount,
                      equals(NotificationType.values.length),
                      reason: 'deleteNotificationChannelCount');
                } else {
                  expect(alarmServiceStartCount, equals(0),
                      reason: 'alarmServiceStartCount');
                  expect(alarmCancelCount, equals(0),
                      reason: 'alarmCancelCount');
                  expect(initializeCount, equals(0), reason: 'initializeCount');
                  expect(getNotificationAppLaunchDetailsCount, equals(0),
                      reason: 'getNotificationAppLaunchDetailsCount');
                  expect(cancelAllCount, equals(0), reason: 'cancelAllCount');
                  expect(deleteNotificationChannelCount, equals(0),
                      reason: 'deleteNotificationChannelCount');
                }

                widgetTester.clearAllMockMethodCallHandler();
              },
            );
          },
        );
      },
    );
