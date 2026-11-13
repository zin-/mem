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
  final fridayThreeWeeksAgo = DateTime(2026, 10, 23, 14);
  final thursday = DateTime(2026, 11, 12, 14);
  final wednesday = DateTime(2026, 11, 11, 14);
  final tuesday = DateTime(2026, 11, 10, 14);
  final monday = DateTime(2026, 11, 9, 14);
  final sunday = DateTime(2026, 11, 8, 14);
  final saturday = DateTime(2026, 11, 7, 14);

  Act started(int memId, DateTime at) => Act.by(
        memId,
        startWhen: DateAndTime(at.year, at.month, at.day, at.hour, at.minute),
        endWhen:
            DateAndTime(at.year, at.month, at.day, at.hour, at.minute + 30),
      );

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

  List<int> ids(Iterable<Act> acts, Iterable<MemEntity> mems) =>
      HabitualMems.of(
        acts,
        mems,
        now: now,
      ).mems.map((mem) => mem.id).toList();

  group('HabitualMems', () {
    test('includes a mem with two acts on today\'s weekday', () {
      expect(
        ids(
          [
            started(1, friday),
            started(1, previousFriday),
          ],
          [mem(1)],
        ),
        [1],
      );
    });

    test(
        'excludes a mem with one act on today\'s weekday however many other weekdays it has',
        () {
      expect(
        ids(
          [
            started(1, friday),
            started(1, thursday),
            started(1, wednesday),
            started(1, tuesday),
            started(1, monday),
            started(1, sunday),
            started(1, saturday),
            started(2, friday),
            started(2, previousFriday),
          ],
          [mem(1), mem(2)],
        ),
        [2],
      );
    });

    test('orders by today\'s weekday count descending, then id ascending', () {
      expect(
        ids(
          [
            started(4, friday),
            started(4, previousFriday),
            started(4, thursday),
            started(4, wednesday),
            started(4, tuesday),
            started(4, monday),
            started(2, friday),
            started(2, previousFriday),
            started(2, fridayThreeWeeksAgo),
            started(7, friday),
            started(7, previousFriday),
            started(1, friday),
          ],
          [mem(4), mem(2), mem(7), mem(1)],
        ),
        [2, 4, 7],
      );
    });

    test('excludes archived and done mems', () {
      expect(
        ids(
          [
            started(1, friday),
            started(1, previousFriday),
            started(2, friday),
            started(2, previousFriday),
            started(3, friday),
            started(3, previousFriday),
          ],
          [
            mem(1, archivedAt: DateTime(2026, 6, 2)),
            mem(2, doneAt: DateTime(2026, 6, 3)),
            mem(3),
          ],
        ),
        [3],
      );
    });
  });
}
