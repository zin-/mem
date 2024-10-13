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

      // TODO 仕様を整理する
      // 要望としては「実施する順」に並んでいてほしい
      //  - Time
      //    - On
      //      - 時分指定がないものは1日の開始時間が指定されているものとして扱う
      //        - 期間の終了の場合は翌日の開始時間の1分前として扱う
      //    - At
      //      - 次は、時分の指定があるもの
      //    - Repeat
      //      - repeatやrepeatByDayなどがあるもの
      //      - 最新のActから考える
      //        - repeatByDayやrepeatByWeekOfDayなど
      //  - ↑で決まらずAfterActStartedがあるもの
      //  - Plain
      //  - Done, Archived
      //    - 完了しているものやアーカイブしたものは下位
      //    - 同時に見ることはほとんどないはずではあるけど
      // TODO 期間と繰り返しの両方を持つ場合は？
      //  期間内は繰り返しという認識で良いはず
      final mems = [
        {
          mem: Mem("plain", null, null),
          latestAct: null,
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
        {
          mem: Mem("has period start", null,
              DateAndTimePeriod(start: DateAndTime(0))),
          latestAct: null,
          memNotifications: null
        },
      ];
      final results = [
        // plain
        0, -1, -1, 0,
        // FIXME 期間なしとありで差がないのはおかしい
        //  期間の比較がMemNotificationsがないと実施されないようになっていておかしい
        0,
        // is archived
        1, 0, 1, 1, 1,
        // is done
        1, -1, 0, 1, 1,
        // has mem notifications
        0, -1, -1, 0, 0,
        // has period start
        0, -1, -1, 0, 0,
      ];

      for (final a in mems) {
        for (final b in mems) {
          test(
            "${(a[mem] as Mem).name} compareTo ${(b[mem] as Mem).name}.",
            () {
              final result = (a[mem] as Mem).compareTo((b[mem] as Mem),
                  latestActOfThis: (a[latestAct] as Act?),
                  latestActOfOther: (b[latestAct] as Act?),
                  memNotificationsOfThis:
                      (a[memNotifications] as Iterable<MemNotification>?),
                  memNotificationsOfOther:
                      (b[memNotifications] as Iterable<MemNotification>?),
                  startOfDay: startOfDay,
                  now: now);

              expect(result, equals(results.removeAt(0)));
            },
          );
        }
      }
    });
