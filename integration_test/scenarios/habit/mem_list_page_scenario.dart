import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/view/timer.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';

import '../helpers.dart';

const _name = "MemListPage scenario";

extension on WidgetTester {
  void expectMemListItem(
    int at,
    List<String?> texts,
    List<IconData> icons,
    List<IconData> noIcons,
  ) {
    final memListItemFinder = find.byType(ListTile).at(at);

    final textsFinder = find.descendant(
      of: memListItemFinder,
      matching: find.byType(Text),
    );
    expect(
      widgetList(textsFinder),
      hasLength(texts.length),
    );
    texts.forEachIndexed((index, text) {
      if (text != null) {
        expect(
          widget<Text>(
            textsFinder.at(index),
          ).data,
          equals(text),
        );
      }
    });

    expect(
      widgetList(find.descendant(
        of: memListItemFinder,
        matching: find.byType(Icon),
      )),
      hasLength(icons.length),
    );
    icons.forEachIndexed((index, icon) {
      expect(
        widget<Icon>(
          find
              .descendant(
                of: memListItemFinder,
                matching: find.byType(Icon),
              )
              .at(index),
        ).icon,
        equals(icon),
      );
    });
    for (var noIcon in noIcons) {
      expect(
        find.descendant(
          of: memListItemFinder,
          matching: find.byIcon(noIcon),
        ),
        findsNothing,
      );
    }
  }
}

void main() => group(_name, () {
      const insertedMemNameBase = '$_name: inserted mem - name';
      const memWithNoActName = "no act - $insertedMemNameBase";
      const memWithActiveActName = "active act - $insertedMemNameBase";
      const memWithFinishedActName = "finished act - $insertedMemNameBase";
      const memWithPausedActName = "paused act - $insertedMemNameBase";
      const memWithNoNotificationName =
          "no notification - $insertedMemNameBase";

      late final DatabaseAccessor dbA;
      late final int memWithNoActId;
      late final int memWithActiveActId;
      late final int memWithFinishedActId;
      late final int memWithPausedActId;
      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
        await clearAllTestDatabaseRows(databaseDefinition);

        memWithNoActId = await dbA.insert(defTableMems, {
          defColMemsName.name: memWithNoActName,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableMemNotifications, {
          defFkMemNotificationsMemId.name: memWithNoActId,
          defColMemNotificationsTime.name: 60,
          defColMemNotificationsType.name:
              MemNotificationType.afterActStarted.name,
          defColMemNotificationsMessage.name:
              '$_name: mem notification message',
          defColCreatedAt.name: zeroDate,
        });

        memWithActiveActId = await dbA.insert(defTableMems, {
          defColMemsName.name: memWithActiveActName,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableMemNotifications, {
          defFkMemNotificationsMemId.name: memWithActiveActId,
          defColMemNotificationsTime.name: 120,
          defColMemNotificationsType.name:
              MemNotificationType.afterActStarted.name,
          defColMemNotificationsMessage.name:
              '$_name: mem notification message',
          defColCreatedAt.name: zeroDate,
        });

        memWithFinishedActId = await dbA.insert(defTableMems, {
          defColMemsName.name: memWithFinishedActName,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableMemNotifications, {
          defFkMemNotificationsMemId.name: memWithFinishedActId,
          defColMemNotificationsTime.name: 180,
          defColMemNotificationsType.name:
              MemNotificationType.afterActStarted.name,
          defColMemNotificationsMessage.name:
              '$_name: mem notification message',
          defColCreatedAt.name: zeroDate,
        });

        memWithPausedActId = await dbA.insert(defTableMems, {
          defColMemsName.name: memWithPausedActName,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(
          defTableMemNotifications,
          {
            defFkMemNotificationsMemId.name: memWithPausedActId,
            defColMemNotificationsTime.name: 120,
            defColMemNotificationsType.name:
                MemNotificationType.afterActStarted.name,
            defColMemNotificationsMessage.name:
                '$_name: mem notification message',
            defColCreatedAt.name: zeroDate,
          },
        );

        await dbA.insert(defTableMems, {
          defColMemsName.name: memWithNoNotificationName,
          defColCreatedAt.name: zeroDate,
        });
      });

      setUp(() async {
        await dbA.delete(defTableActs);

        await dbA.insert(defTableActs, {
          defFkActsMemId.name: memWithActiveActId,
          defColActsStart.name: zeroDate,
          defColActsStartIsAllDay.name: false,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableActs, {
          defFkActsMemId.name: memWithFinishedActId,
          defColActsStart.name: zeroDate,
          defColActsStartIsAllDay.name: false,
          defColActsEnd.name: zeroDate,
          defColActsEndIsAllDay.name: false,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableActs, {
          defFkActsMemId.name: memWithPausedActId,
          defColActsStart.name: null,
          defColActsStartIsAllDay.name: null,
          defColActsEnd.name: null,
          defColActsEndIsAllDay.name: null,
          defColCreatedAt.name: zeroDate,
        });
      });

      group(': act', () {
        group(': no act', () {
          const targetAt = 2;

          testWidgets('Show.', (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            widgetTester.expectMemListItem(
              targetAt,
              [memWithNoActName, null],
              [Icons.stop, Icons.play_arrow],
              [Icons.pause],
            );
          });

          testWidgets('Start.',
              // 時間に関するテストなのでリトライ可能とする
              retry: maxRetryCount, (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.permissionHandler,
            );
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications,
            );

            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.descendant(
              of: find.byType(ListTile).at(targetAt),
              matching: find.byIcon(Icons.play_arrow),
            ));
            await widgetTester.pumpAndSettle();

            widgetTester.expectMemListItem(
              0,
              [memWithNoActName, "00:00:00", null],
              [Icons.pause, Icons.stop],
              [Icons.play_arrow],
            );

            await widgetTester.pumpAndSettle(elapsePeriod * 2);

            expect(find.text("00:00:00"), findsNothing);

            final acts = await dbA.select(
              defTableActs,
              where: '${defFkActsMemId.name} = ?',
              whereArgs: [memWithNoActId],
            );
            expect(acts, hasLength(1));
          });
        });

        group(': active act', () {
          const targetAt = 0;

          testWidgets(': show.', (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            widgetTester.expectMemListItem(
              targetAt,
              [memWithActiveActName, null, null],
              [Icons.pause, Icons.stop],
              [Icons.play_arrow],
            );
          });

          testWidgets('Finish.', (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.permissionHandler,
            );
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications,
            );

            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.descendant(
              of: find.byType(ListTile).at(targetAt),
              matching: find.byIcon(Icons.stop),
            ));
            await widgetTester.pumpAndSettle();

            widgetTester.expectMemListItem(
              2,
              [memWithActiveActName, null],
              [Icons.stop, Icons.play_arrow],
              [Icons.pause],
            );

            final acts = await dbA.select(
              defTableActs,
              where: '${defFkActsMemId.name} = ?',
              whereArgs: [memWithActiveActId],
            );
            expect(acts, hasLength(1));
          });

          testWidgets(': pause.', (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.permissionHandler,
            );
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications,
            );

            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.descendant(
              of: find.byType(ListTile).at(targetAt),
              matching: find.byIcon(Icons.pause),
            ));
            await widgetTester.pumpAndSettle(const Duration(seconds: 3));

            widgetTester.expectMemListItem(
              0,
              [memWithActiveActName, null],
              [Icons.stop, Icons.play_arrow],
              [Icons.pause],
            );

            final acts = await dbA.select(
              defTableActs,
              where: '${defFkActsMemId.name} = ?',
              whereArgs: [memWithActiveActId],
            );
            expect(acts, hasLength(2));
          });
        });

        group(': finished act', () {
          const targetAt = 3;

          testWidgets('Show.', (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            widgetTester.expectMemListItem(
              targetAt,
              [memWithFinishedActName, null],
              [Icons.stop, Icons.play_arrow],
              [Icons.pause],
            );
          });

          testWidgets(': start.',
              // 時間に関するテストなのでリトライ可能とする
              retry: maxRetryCount, (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.permissionHandler,
            );
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications,
            );

            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.descendant(
              of: find.byType(ListTile).at(targetAt),
              matching: find.byIcon(Icons.play_arrow),
            ));
            await widgetTester.pumpAndSettle();

            widgetTester.expectMemListItem(
              0,
              [memWithFinishedActName, "00:00:00", null],
              [Icons.pause, Icons.stop],
              [Icons.play_arrow],
            );

            await widgetTester.pumpAndSettle(elapsePeriod * 2);

            expect(find.text("00:00:00"), findsNothing);

            final acts = await dbA.select(
              defTableActs,
              where: '${defFkActsMemId.name} = ?',
              whereArgs: [memWithFinishedActId],
            );
            expect(acts, hasLength(2));
          });
        });

        group(': paused act', () {
          const targetAt = 1;

          testWidgets(': show.', (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            widgetTester.expectMemListItem(
              targetAt,
              [memWithPausedActName, null],
              [Icons.stop, Icons.play_arrow],
              [Icons.pause],
            );
          });

          testWidgets(': start.',
              // 時間に関するテストなのでリトライ可能とする
              retry: maxRetryCount, (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.permissionHandler,
            );
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications,
            );

            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.descendant(
              of: find.byType(ListTile).at(targetAt),
              matching: find.byIcon(Icons.play_arrow),
            ));
            await widgetTester.pumpAndSettle();

            widgetTester.expectMemListItem(
              0,
              [memWithPausedActName, "00:00:00", null],
              [Icons.pause, Icons.stop],
              [Icons.play_arrow],
            );

            await widgetTester.pumpAndSettle(elapsePeriod * 2);

            expect(find.text("00:00:00"), findsNothing);

            final acts = await dbA.select(
              defTableActs,
              where: '${defFkActsMemId.name} = ?',
              whereArgs: [memWithPausedActId],
            );
            expect(acts, hasLength(1));
          });

          testWidgets(': finish.', (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.permissionHandler,
            );
            widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications,
            );

            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(
              find.descendant(
                of: find.byType(ListTile).at(targetAt),
                matching: find.byIcon(Icons.stop),
              ),
            );
            await widgetTester.pumpAndSettle();

            widgetTester.expectMemListItem(
              3,
              [memWithPausedActName, null],
              [Icons.stop, Icons.play_arrow],
              [Icons.pause],
            );

            final acts = await dbA.select(
              defTableActs,
              where: '${defFkActsMemId.name} = ?',
              whereArgs: [memWithPausedActId],
            );
            expect(acts, hasLength(1));
          });
        });
      });
    });
