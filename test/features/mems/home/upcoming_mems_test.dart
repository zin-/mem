import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/home/upcoming_mems.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

import '../../../entity_factories.dart';
import '../list/helpers.dart';

void main() {
  final startOfToday = DateTime(2024, 10, 12, 9);
  final now = DateTime(2024, 10, 12, 12);
  final createdAt = DateTime(2024, 6, 1);

  MemEntity at(
    int id,
    DateTime when, {
    DateTime? doneAt,
    DateTime? archivedAt,
  }) =>
      savedMem(
        id: id,
        name: 'Mem $id',
        createdAt: createdAt,
        updatedAt: createdAt,
        notifyOn: when,
        notifyAt: when,
        doneAt: doneAt,
        archivedAt: archivedAt,
      );

  MemEntity plain(int id) => savedMem(
        id: id,
        name: 'Mem $id',
        createdAt: createdAt,
        updatedAt: createdAt,
      );

  List<int> ids(
    Iterable<MemEntity> mems, [
    Iterable<SavedMemNotificationEntityV1> savedMemNotifications = const [],
    Map<int, int> periodCountByMemId = const {},
  ]) =>
      upcomingMems(
        mems,
        savedMemNotifications,
        now: now,
        startOfToday: startOfToday,
        periodCountByMemId: periodCountByMemId,
      ).map((mem) => mem.id).toList();

  group('upcomingMems', () {
    test('returns the three soonest notifyAt in ascending order', () {
      expect(
        ids(
          [
            at(1, DateTime(2024, 10, 12, 15)),
            plain(2),
            at(4, DateTime(2024, 10, 12, 16)),
            at(3, DateTime(2024, 10, 12, 14)),
          ],
          [
            savedRepeatAtHourNotification(id: 1, memId: 2, hour: 13),
          ],
        ),
        [2, 3, 1],
      );
    });

    test('drops notifyAt before now and keeps notifyAt equal to now', () {
      expect(
        ids([
          at(1, DateTime(2024, 10, 12, 11)),
          at(2, now),
          at(3, DateTime(2024, 10, 12, 13)),
        ]),
        [2, 3],
      );
    });

    test('drops mems whose notifyAt is null', () {
      expect(
        ids(
          [
            plain(1),
            plain(2),
            at(3, DateTime(2024, 10, 12, 13)),
          ],
          [
            savedAfterActStartedNotification(id: 1, memId: 2),
            savedRepeatAtHourNotification(id: 2, memId: 99, hour: 13),
          ],
        ),
        [3],
      );
    });

    test('drops archived and done mems', () {
      expect(
        ids([
          at(1, DateTime(2024, 10, 12, 13), archivedAt: DateTime(2024, 6, 2)),
          at(2, DateTime(2024, 10, 12, 14), doneAt: DateTime(2024, 6, 3)),
          at(3, DateTime(2024, 10, 12, 18)),
        ]),
        [3],
      );
    });

    test('orders the same notifyAt by ascending id', () {
      final when = DateTime(2024, 10, 12, 15);

      expect(ids([at(5, when), at(2, when)]), [2, 5]);
    });

    test('returns fewer than three when fewer qualify', () {
      expect(
        ids([
          at(2, DateTime(2024, 10, 13, 10)),
          at(1, DateTime(2024, 10, 12, 18)),
        ]),
        [1, 2],
      );
      expect(ids(const <MemEntity>[]), isEmpty);
    });

    test(
      'orders by notifyAt that uses target and todayCount like the mem list',
      () {
        const intervalSeconds = 2 * 60 * 60;
        const dailyTarget = 4;
        const belowDailyTarget = 1;
        final dailyCountTarget = Target(
          memId: 1,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: dailyTarget,
          period: Period.aDay,
          secondsAfterLastAct: intervalSeconds,
        );
        final latestAct = Act.by(
          1,
          startWhen: DateAndTime(2024, 10, 12, 9),
          endWhen: DateAndTime(2024, 10, 12, 10),
        );
        final dailyCountMem = savedMem(
          id: 1,
          name: 'Mem 1',
          createdAt: createdAt,
          updatedAt: createdAt,
          target: dailyCountTarget,
          latestAct: latestAct,
        );
        final laterToday = at(2, DateTime(2024, 10, 12, 15));
        final notifications = [
          savedRepeatAtHourNotification(id: 1, memId: 1, hour: 9),
        ];

        expect(
          ids(
            [dailyCountMem, laterToday],
            notifications,
            {1: belowDailyTarget},
          ),
          // below target → same-day interval (12:00) before laterToday (15:00)
          [1, 2],
        );
        expect(
          ids(
            [dailyCountMem, laterToday],
            notifications,
            {1: dailyTarget},
          ),
          // reached → schedule anchor pushes to tomorrow 09:00
          [2, 1],
        );
      },
    );
  });
}
