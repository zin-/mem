import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:test/test.dart';

const _name = 'MemNotification test';

void main() => group(_name, () {
      group(': nextNotifyAt', () {
        final startOfToday = DateTime(2024, 10, 12, 0, 0, 0, 0, 0);

        group(': repeat', () {
          final memRepeatNotifications = [
            null,
            MemNotification(
                0, MemNotificationType.repeat, 3600 + 120, "repeat at 01:02"),
          ];
          final memRepeatByNDayNotifications = [
            null,
            MemNotification(
                0, MemNotificationType.repeatByNDay, 2, "repeat by 2 day"),
          ];
          final memRepeatByDayOfWeekNotifications = [
            null,
            MemNotification(
                0, MemNotificationType.repeatByDayOfWeek, 6, "repeat on Sat"),
          ];

          final acts = {
            'no act': null,
            'day before yesterday act': Act(
                0,
                DateAndTimePeriod(
                    start: DateAndTime.from(startOfToday)
                        .subtract(const Duration(days: 2)),
                    end: DateAndTime.from(startOfToday))),
            'yesterday act': Act(
                0,
                DateAndTimePeriod(
                    start: DateAndTime.from(startOfToday)
                        .subtract(const Duration(days: 1)),
                    end: DateAndTime.from(startOfToday))),
            'today act': Act(
                0,
                DateAndTimePeriod(
                    start: DateAndTime.from(startOfToday),
                    end: DateAndTime.from(startOfToday))),
          };

          final nextSaturday = DateTime(
              startOfToday.year, startOfToday.month, startOfToday.day + 7);
          final dayAfterTomorrow = DateTime(
              startOfToday.year, startOfToday.month, startOfToday.day + 2);
          final tomorrow = DateTime(
              startOfToday.year, startOfToday.month, startOfToday.day + 1);
          final todayWithTime = DateTime(
              startOfToday.year, startOfToday.month, startOfToday.day, 1, 2);
          final tomorrowWithTime = DateTime(startOfToday.year,
              startOfToday.month, startOfToday.day + 1, 1, 2);
          final nextSaturdayWithTime = DateTime(startOfToday.year,
              startOfToday.month, startOfToday.day + 7, 1, 2);
          final dayAfterTomorrowWithTime = DateTime(startOfToday.year,
              startOfToday.month, startOfToday.day + 2, 1, 2);

          final expectedList = [
            // null
            null,
            null,
            null,
            null,

            startOfToday,
            startOfToday,
            startOfToday,
            nextSaturday,

            startOfToday,
            startOfToday,
            tomorrow,
            dayAfterTomorrow,

            startOfToday,
            startOfToday,
            nextSaturday,
            nextSaturday,

            // repeat at 01:02
            todayWithTime,
            todayWithTime,
            todayWithTime,
            tomorrowWithTime,

            todayWithTime,
            todayWithTime,
            todayWithTime,
            nextSaturdayWithTime,

            todayWithTime,
            todayWithTime,
            tomorrowWithTime,
            dayAfterTomorrowWithTime,

            todayWithTime,
            todayWithTime,
            nextSaturdayWithTime,
            nextSaturdayWithTime,
          ];

          for (final a in memRepeatNotifications) {
            for (final b in memRepeatByNDayNotifications) {
              for (final c in memRepeatByDayOfWeekNotifications) {
                for (final act in acts.entries) {
                  test(
                      ': ${a?.message ?? "null"}'
                      ', ${b?.message ?? "null"}'
                      ', ${c?.message ?? "null"}'
                      ', ${act.key}'
                      '.', () {
                    final result = MemNotification.nextNotifyAt(
                        [a, b, c].whereType<MemNotification>(),
                        startOfToday,
                        act.value);

                    expect(result, equals(expectedList.removeAt(0)));
                  });
                }
              }
            }
          }
        });
      });
    });