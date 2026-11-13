import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mems/home/habitual_mems.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

import '../../../entity_factories.dart';

void main() {
  final now = DateTime(2026, 11, 13, 14, 30);
  final createdAt = DateTime(2026, 6, 1);

  final friday = DateTime(2026, 11, 13, 14);
  final previousFriday = DateTime(2026, 11, 6, 14);
  final thursday = DateTime(2026, 11, 12, 14);
  final wednesday = DateTime(2026, 11, 11, 14);
  final tuesday = DateTime(2026, 11, 10, 14);

  Act spanning(int memId, DateTime at, Duration length) {
    final end = at.add(length);
    DateAndTime time(DateTime value) => DateAndTime(
          value.year,
          value.month,
          value.day,
          value.hour,
          value.minute,
          value.second,
          value.millisecond,
          value.microsecond,
        );
    return Act.by(memId, startWhen: time(at), endWhen: time(end));
  }

  Act started(int memId, DateTime at) =>
      spanning(memId, at, const Duration(minutes: 30));

  MemEntity mem(
    int id, {
    DateTime? doneAt,
    DateTime? archivedAt,
  }) =>
      savedMem(
        id: id,
        name: 'Mem $id',
        createdAt: createdAt,
        updatedAt: createdAt,
        doneAt: doneAt,
        archivedAt: archivedAt,
      );

  List<int> ids(
    Iterable<Act> acts,
    Iterable<MemEntity> mems, {
    DateTime? at,
  }) =>
      HabitualMems.of(
        acts,
        mems,
        now: at ?? now,
      ).mems.map((mem) => mem.id).toList();

  group('HabitualMems', () {
    test('includes a mem with one act in the window', () {
      expect(
        ids([started(1, friday)], [mem(1)]),
        [1],
      );
    });

    test('includes archived and done mems', () {
      expect(
        ids(
          [
            started(1, friday),
            started(2, friday),
            started(3, friday),
          ],
          [
            mem(1, archivedAt: DateTime(2026, 6, 2)),
            mem(2, doneAt: DateTime(2026, 6, 3)),
            mem(3),
          ],
        ),
        [1, 2, 3],
      );
    });

    test('places longer total time above more acts', () {
      expect(
        ids(
          [
            spanning(1, thursday, const Duration(hours: 3)),
            spanning(2, thursday, const Duration(minutes: 10)),
            spanning(2, wednesday, const Duration(minutes: 10)),
            spanning(2, tuesday, const Duration(minutes: 10)),
          ],
          [mem(2), mem(1)],
        ),
        [1, 2],
      );
    });

    test('places the higher score above when total time matches', () {
      expect(
        ids(
          [
            spanning(1, friday, const Duration(minutes: 15)),
            spanning(1, previousFriday, const Duration(minutes: 15)),
            spanning(2, thursday, const Duration(minutes: 10)),
            spanning(2, wednesday, const Duration(minutes: 10)),
            spanning(2, tuesday, const Duration(minutes: 10)),
          ],
          [mem(2), mem(1)],
        ),
        [1, 2],
      );
    });

    test('places the lower id first when total time and score match', () {
      expect(
        ids(
          [
            started(4, thursday),
            started(1, wednesday),
          ],
          [mem(4), mem(1)],
        ),
        [1, 4],
      );
    });

    test(
        'counts an act that ends inside the window and omits one that misses it',
        () {
      expect(
        ids(
          [
            spanning(1, DateTime(2026, 11, 13, 12), const Duration(hours: 2)),
            spanning(2, DateTime(2026, 11, 13, 10), const Duration(hours: 1)),
            spanning(3, DateTime(2026, 11, 13, 16), const Duration(hours: 1)),
          ],
          [mem(3), mem(2), mem(1), mem(4)],
        ),
        [1],
      );
    });

    test(
        'includes an act of 24 hours and omits a shorter act that misses the window',
        () {
      expect(
        ids(
          [
            spanning(
              1,
              DateTime(2026, 11, 12, 16),
              const Duration(hours: 24),
            ),
            spanning(
              2,
              DateTime(2026, 11, 12, 16),
              const Duration(hours: 20),
            ),
          ],
          [mem(2), mem(1)],
        ),
        [1],
      );
    });

    test('includes a morning act when now is late the same day', () {
      expect(
        ids(
          [
            spanning(
              1,
              DateTime(2026, 11, 13, 0, 10),
              const Duration(minutes: 10),
            ),
          ],
          [mem(1)],
          at: DateTime(2026, 11, 13, 23, 30),
        ),
        [1],
      );
    });

    test('includes acts that overlap a window across midnight', () {
      final at = DateTime(2026, 11, 13, 0, 30);
      expect(
        ids(
          [
            spanning(
              1,
              DateTime(2026, 11, 12, 23),
              const Duration(minutes: 75),
            ),
            spanning(2, DateTime(2026, 11, 12, 22), const Duration(hours: 1)),
            spanning(3, DateTime(2026, 11, 13, 1), const Duration(minutes: 20)),
            spanning(
              4,
              DateTime(2026, 11, 12, 23, 40),
              const Duration(minutes: 10),
            ),
          ],
          [mem(2), mem(3), mem(1), mem(4)],
          at: at,
        ),
        [3, 1, 4],
      );
    });
  });
}
