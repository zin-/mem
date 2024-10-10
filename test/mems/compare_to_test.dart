import 'package:flutter/material.dart';
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
      const startOfDay = TimeOfDay(hour: 0, minute: 0);
      final now = DateTime.now();

      final mems = [
        {
          mem: Mem("plain", null, null),
          latestAct: null,
          memNotifications: null
        },
        {
          mem: Mem("has active act", null, null),
          latestAct: Act(0, DateAndTimePeriod(start: DateAndTime(0))),
          memNotifications: null
        },
        {
          mem: SavedMemEntity("is archived", null, null)
            ..id = 0
            ..createdAt = DateTime(0)
            ..updatedAt = null
            ..archivedAt = DateTime(0),
          latestAct: null,
          memNotifications: null
        },
        {
          mem: Mem("is done", DateAndTime(0), null),
          latestAct: null,
          memNotifications: null
        },
        {
          mem: Mem("has mem notifications", null, null),
          latestAct: null,
          memNotifications: [
            MemNotification(0, MemNotificationType.repeat, 0, "message")
          ]
        },
      ];
      final results = [
        // plain
        0, 1, -1, -1, 0,
        // has active act
        -1, 0, -1, -1, -1,
        // is archived
        1, 1, 0, 1, 1,
        // is done
        1, 1, -1, 0, 1,
        // has mem notifications
        0, 1, -1, -1, 0,
      ];

      for (final a in mems) {
        for (final b in mems) {
          test(
            "${(a[mem] as Mem).name} compareTo ${(b[mem] as Mem).name}.",
            () {
              final result = (a[mem] as Mem).compareTo((b[mem] as Mem),
                  latestActOfThis: (a[latestAct] as Act?),
                  latestActOfOther: (b[latestAct] as Act?),
                  startOfDay: startOfDay,
                  now: now);

              expect(result, equals(results.removeAt(0)));
            },
          );
        }
      }

      test(': mem notifications.', () {
        final memA = Mem("$_name - a", null, null);
        final memB = Mem("$_name - b", DateAndTime.now(), null);

        final result = memA.compareTo(memB);

        expect(result, equals(-1));
      });
    });
