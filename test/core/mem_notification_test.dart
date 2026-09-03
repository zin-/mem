import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';

void main() {
  group('MemNotification', () {
    test(
      'repeat by day of week.',
      () {
        const memId = 1;
        const time = 2;

        final repeatByDayOfWeek = MemNotification.by(memId,
            MemNotificationType.repeatByDayOfWeek, time, "repeatByDayOfWeek");

        expect(repeatByDayOfWeek.isRepeatByDayOfWeek(), isTrue);
        expect(repeatByDayOfWeek.memId, equals(memId));
        expect(repeatByDayOfWeek.time, equals(time));
      },
    );

    group('toOneLine', () {
      const weekdayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      const sundayFirstWeekdays = [
        DateTime.sunday,
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
      ];
      String formatWeekday(int weekday) => weekdayNames[weekday % 7];
      String buildAfterActStartedNotificationText(String at) =>
          "after act at $at";
      String formatTime(TimeOfDay time) =>
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      test('no enables.', () {
        const memId = 1;

        final oneLine = MemNotification.toOneLine(
          [
            MemNotification.by(
                memId, MemNotificationType.repeat, null, "repeat")
          ],
          (w) => fail("no call"),
          sundayFirstWeekdays,
          (a) => fail("no call"),
          (t) => fail("no call"),
        );

        expect(oneLine, isNull);
      });

      group('repeat', () {
        test('repeat at 0:0.', () {
          const memId = 1;
          const repeatAt = 0;

          final oneLine = MemNotification.toOneLine(
            [
              MemNotification.by(
                  memId, MemNotificationType.repeat, repeatAt, "")
            ],
            (w) => fail("no call"),
            sundayFirstWeekdays,
            (a) => fail("no call"),
            (t) => fail("no call"),
          );

          expect(oneLine, isNull);
        });

        test('repeat at 05:00 by 2 day.', () {
          const memId = 1;
          const repeatAt = (5 * 60) * 60;
          const repeatByNDay = 2;

          final oneLine = MemNotification.toOneLine(
            [
              MemNotification.by(
                  memId, MemNotificationType.repeat, repeatAt, ""),
              MemNotification.by(
                  memId, MemNotificationType.repeatByNDay, repeatByNDay, "")
            ],
            (w) => fail("no call"),
            sundayFirstWeekdays,
            (at) => fail("no call"),
            (t) => fail("no call"),
          );

          expect(oneLine, isNull);
        });

        test('repeat at 12:00 by 3 day on Mon.', () {
          const memId = 1;
          const repeatAt = (5 * 60) * 60;
          const repeatByNDay = 2;

          final oneLine = MemNotification.toOneLine(
            [
              MemNotification.by(
                  memId, MemNotificationType.repeat, repeatAt, ""),
              MemNotification.by(
                  memId, MemNotificationType.repeatByNDay, repeatByNDay, ""),
              MemNotification.by(
                  memId, MemNotificationType.repeatByDayOfWeek, 1, "")
            ],
            formatWeekday,
            sundayFirstWeekdays,
            (at) => fail("no call"),
            (t) => fail("no call"),
          );

          expect(oneLine, equals("Mon"));
        });
      });

      test('repeat by Tue.', () {
        const memId = 1;

        final oneLine = MemNotification.toOneLine(
          [
            MemNotification.by(memId, MemNotificationType.repeatByDayOfWeek, 2,
                "repeatByDayOfWeek")
          ],
          formatWeekday,
          sundayFirstWeekdays,
          (a) => a,
          (t) => fail("no call"),
        );

        expect(oneLine, equals("Tue"));
      });

      test('repeat by Sun and Mon follows weekdayOrder.', () {
        const memId = 1;

        final notifications = [
          MemNotification.by(memId, MemNotificationType.repeatByDayOfWeek,
              DateTime.monday, ""),
          MemNotification.by(memId, MemNotificationType.repeatByDayOfWeek,
              DateTime.sunday, ""),
        ];

        expect(
          MemNotification.toOneLine(
            notifications,
            formatWeekday,
            sundayFirstWeekdays,
            (a) => fail("no call"),
            (t) => fail("no call"),
          ),
          "Sun, Mon",
        );
        expect(
          MemNotification.toOneLine(
            notifications,
            formatWeekday,
            [
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
              DateTime.saturday,
              DateTime.sunday,
            ],
            (a) => fail("no call"),
            (t) => fail("no call"),
          ),
          "Mon, Sun",
        );
      });

      test('after act', () {
        const memId = 1;
        const time = 2;
        final oneLine = MemNotification.toOneLine(
          [
            MemNotification.by(
                memId, MemNotificationType.afterActStarted, time, "")
          ],
          (w) => fail("no call"),
          sundayFirstWeekdays,
          buildAfterActStartedNotificationText,
          formatTime,
        );

        expect(
          oneLine,
          buildAfterActStartedNotificationText(formatTime(
            const TimeOfDay(hour: 0, minute: 0),
          )),
        );
      });
    });
  });

  test('MemNotificationType from unexpected name throw.', () {
    const name = 'unexpected name';

    expect(() => MemNotificationType.fromName(name), throwsA((e) {
      expect(e.message, 'Unexpected name: "$name".');
      return true;
    }));
  });
}
