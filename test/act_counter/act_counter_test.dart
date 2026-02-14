import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/counter/act_counter.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mems/mem.dart';

void main() {
  group('ActCounter.from', () {
    test(": updatedAt is last act start.", () {
      const memId = 1;
      final zeroDate = DateTime(0);
      final oneDate = DateTime(1);

      final savedMem = Mem(memId, "constructor", null, null);
      final acts = [
        ActEntity(
            memId, DateAndTime.now(), null, null, 1, zeroDate, oneDate, null),
        ActEntity(
            memId, DateAndTime.now(), null, null, 2, zeroDate, null, null),
      ];

      final actCounter = ActCounter.from(savedMem, acts);

      expect(actCounter.updatedAt, equals(acts[0].start));
    });
    test(": updatedAt is last act end.", () {
      const memId = 1;
      final zeroDate = DateTime(0);
      final oneDate = DateTime(1);

      final savedMem = Mem(memId, "constructor", null, null);
      final acts = [
        ActEntity(memId, DateAndTime(0), DateAndTime.now(), null, 3, zeroDate,
            oneDate, null),
        ActEntity(
            memId, DateAndTime.now(), null, null, 4, zeroDate, null, null),
      ];

      final actCounter = ActCounter.from(savedMem, acts);

      expect(actCounter.updatedAt, equals(acts[0].end));
    });
  });

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
