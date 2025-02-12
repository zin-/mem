import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/mems/mem_notification.dart';

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
      String buildAfterActStartedNotificationText(String at) =>
          "after act at $at";

      test('no enables.', () {
        const memId = 1;

        final oneLine = MemNotification.toOneLine(
          [
            MemNotification.by(
                memId, MemNotificationType.repeat, null, "repeat")
          ],
          (a) => fail("no call"),
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
            (a) => fail("no call"),
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
            (at) => fail("no call"),
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
            (at) => fail("no call"),
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
          (a) => a,
        );

        expect(oneLine, equals("Tue"));
      });

      test('after act', () {
        const memId = 1;
        const time = 2;
        final oneLine = MemNotification.toOneLine(
          [
            MemNotification.by(
                memId, MemNotificationType.afterActStarted, time, "")
          ],
          buildAfterActStartedNotificationText,
        );

        expect(
            oneLine,
            buildAfterActStartedNotificationText(
                DateFormat(DateFormat.HOUR24_MINUTE)
                    .format(DateAndTime(0, 0, 0, 0, 0, time))));
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
