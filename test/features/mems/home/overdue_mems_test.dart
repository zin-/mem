import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/home/overdue_mems.dart';
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
      overdueMems(
        mems,
        savedMemNotifications,
        now: now,
        startOfToday: startOfToday,
        periodCountByMemId: periodCountByMemId,
      ).map((mem) => mem.id).toList();

  group('overdueMems', () {
    test('returns every notifyAt before now in ascending order', () {
      expect(
        ids([
          at(1, DateTime(2024, 10, 12, 8)),
          at(4, DateTime(2024, 10, 12, 11)),
          at(3, DateTime(2024, 10, 12, 7)),
          at(5, DateTime(2024, 10, 12, 6)),
          at(6, DateTime(2024, 10, 12, 10)),
        ]),
        [5, 3, 1, 6, 4],
      );
    });

    test('drops notifyAt after now and notifyAt equal to now', () {
      expect(
        ids([
          at(1, DateTime(2024, 10, 12, 11)),
          at(2, now),
          at(3, DateTime(2024, 10, 12, 13)),
        ]),
        [1],
      );
    });

    test('drops mems whose notifyAt is null', () {
      expect(
        ids(
          [
            plain(1),
            plain(2),
            at(3, DateTime(2024, 10, 12, 11)),
          ],
          [
            savedAfterActStartedNotification(id: 1, memId: 2),
            savedRepeatAtHourNotification(id: 2, memId: 99, hour: 8),
          ],
        ),
        [3],
      );
    });

    test('drops archived and done mems', () {
      expect(
        ids([
          at(1, DateTime(2024, 10, 12, 8), archivedAt: DateTime(2024, 6, 2)),
          at(2, DateTime(2024, 10, 12, 9), doneAt: DateTime(2024, 6, 3)),
          at(3, DateTime(2024, 10, 12, 10)),
        ]),
        [3],
      );
    });

    test('orders the same notifyAt by ascending id', () {
      final when = DateTime(2024, 10, 12, 8);

      expect(ids([at(5, when), at(2, when)]), [2, 5]);
    });

    test(
      'includes a count target whose interval is before now and drops it once the day is reached',
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
          endWhen: DateAndTime(2024, 10, 12, 9, 30),
        );
        final dailyCountMem = savedMem(
          id: 1,
          name: 'Mem 1',
          createdAt: createdAt,
          updatedAt: createdAt,
          target: dailyCountTarget,
          latestAct: latestAct,
        );
        final notifications = [
          savedRepeatAtHourNotification(id: 1, memId: 1, hour: 9),
        ];

        expect(
          ids(
            [dailyCountMem],
            notifications,
            {1: belowDailyTarget},
          ),
          // end 09:30 + 2h → 11:30, before now
          [1],
        );
        expect(
          ids(
            [dailyCountMem],
            notifications,
            {1: dailyTarget},
          ),
          // reached → schedule anchor pushes to tomorrow 09:00
          isEmpty,
        );
      },
    );
  });
}
