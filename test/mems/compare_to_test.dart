import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/mems/mem.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_notification.dart';

const _name = 'Mem test: compareTo';

void main() => group(_name, () {
      const mem = 'mem';
      const latestAct = 'latestAct';
      const memNotifications = 'memNotifications';
      final now = DateTime.now();

      final mems = [
        {
          mem: Mem("plain", null, null),
          latestAct: null,
          memNotifications: null,
        },
        {
          mem: SavedMemEntity("is archived", null, null)
            ..id = 0
            ..createdAt = DateTime(0)
            ..updatedAt = null
            ..archivedAt = DateTime(0),
          latestAct: null,
          memNotifications: null,
        },
        {
          mem: Mem("is done", DateAndTime(0), null),
          latestAct: null,
          memNotifications: null,
        },
        {
          mem: Mem("has mem notifications", null, null),
          latestAct: null,
          memNotifications: [
            MemNotification(
              0,
              MemNotificationType.repeat,
              0,
              "repeat",
            )
          ],
        },
        {
          mem: Mem(
            "has period start",
            null,
            DateAndTimePeriod(start: DateAndTime(0)),
          ),
          latestAct: null,
          memNotifications: null,
        },
        {
          mem: Mem("has after act started", null, null),
          latestAct: null,
          memNotifications: [
            MemNotification(
              0,
              MemNotificationType.afterActStarted,
              1,
              "afterActStarted",
            )
          ],
        },
      ];
      final results = [
        // plain
        0, -1, -1, 1, 1, 1,
        // is archived
        1, 0, 1, 1, 1, 1,
        // is done
        1, -1, 0, 1, 1, 1,
        // has mem notifications
        -1, -1, -1, 0, 1, -1,
        // has period start
        -1, -1, -1, -1, 0, -1,
        // has after act started
        -1, -1, -1, 1, 1, 0,
      ];

      for (final a in mems) {
        for (final b in mems) {
          test(
            "${(a[mem] as Mem).name} compareTo ${(b[mem] as Mem).name}.",
            () {
              final result = (a[mem] as Mem).compareTo(
                (b[mem] as Mem),
                now,
                latestActOfThis: (a[latestAct] as Act?),
                latestActOfOther: (b[latestAct] as Act?),
                memNotificationsOfThis:
                    (a[memNotifications] as Iterable<MemNotification>?),
                memNotificationsOfOther:
                    (b[memNotifications] as Iterable<MemNotification>?),
              );

              expect(result, equals(results.removeAt(0)));
            },
          );
        }
      }
    });
