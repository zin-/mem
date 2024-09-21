import 'package:flutter_test/flutter_test.dart';
import 'package:mem/act_counter/act_counter.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/repositories/mem.dart';

void main() {
  test(
    ": constructor.",
    () {
      const memId = 1;
      final zeroDate = DateTime(0);
      final oneDate = DateTime(1);

      final savedMem = SavedMem("constructor", null, null)..id = memId;
      final acts = [
        SavedAct(memId, DateAndTimePeriod(end: DateAndTime.now()))
          ..createdAt = zeroDate
          ..updatedAt = oneDate,
        SavedAct(memId, DateAndTimePeriod.startNow())..createdAt = zeroDate,
      ];

      final actCounter = ActCounter(savedMem, acts);

      expect(actCounter.lastAct, equals(acts[0]));
    },
  );

  group('period', () {
    test(': startDate time is 5:00', () {
      const year = 2023;
      const month = 4;
      final startDate = DateAndTime(year, month, 14, 6, 1);

      final period = ActCounter.period(startDate);

      expect(
        period.toString(),
        DateAndTimePeriod(
          start: DateAndTime(year, month, 14, 5, 0),
          end: DateAndTime(year, month, 15, 5, 0),
        ).toString(),
      );
    });
    test(': startDate time is less than 5:00', () {
      const year = 2023;
      final startDate = DateAndTime(year, 4, 1, 4, 59);

      final period = ActCounter.period(startDate);

      expect(
        period.toString(),
        DateAndTimePeriod(
          start: DateAndTime(year, 3, 31, 5, 0),
          end: DateAndTime(year, 4, 1, 5, 0),
        ).toString(),
      );
    });
  });
}
