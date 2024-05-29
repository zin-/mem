import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/mem_notification.dart';

void main() {
  group('MemNotification', () {
    test(
      'repeat by day of week.',
      () {
        const memId = 1;
        const time = 2;

        final repeatByDayOfWeek =
            MemNotification.repeatByDayOfWeek(memId, time);

        expect(repeatByDayOfWeek.isRepeatByDayOfWeek(), isTrue);
        expect(repeatByDayOfWeek.memId, equals(memId));
        expect(repeatByDayOfWeek.time, equals(time));
      },
    );

    group(
      'toOneLine',
      () {
        String buildRepeatedNotificationText(String at) => "repeat at $at";
        String buildRepeatEveryNDayNotificationText(String nDay, String at) =>
            "repeat at $at by $nDay";
        String buildAfterActStartedNotificationText(String at) =>
            "after act at $at";
        String formatToTimeOfDay(DateAndTime dateAndTime) =>
            "${dateAndTime.hour}:${dateAndTime.minute}";

        test(
          'no enables.',
          () {
            const memId = 1;

            final oneLine = MemNotification.toOneLine(
              [
                MemNotification(
                    memId, MemNotificationType.repeat, null, "message")
              ],
              (at) => fail("no call"),
              (nDay, at) => fail("no call"),
              (a) => fail("no call"),
              (dateAndTime) => fail("no call"),
            );

            expect(oneLine, isNull);
          },
        );

        group(
          'repeat',
          () {
            test(
              'repeat at 0:0.',
              () {
                const memId = 1;
                const repeatAt = 0;

                final oneLine = MemNotification.toOneLine(
                  [
                    MemNotification.repeated(memId).copiedWith(
                      time: () => repeatAt,
                    )
                  ],
                  buildRepeatedNotificationText,
                  (nDay, at) => fail("no call"),
                  (a) => fail("no call"),
                  formatToTimeOfDay,
                );

                expect(
                    oneLine,
                    equals(buildRepeatedNotificationText(formatToTimeOfDay(
                        DateAndTime(0, 0, 0, 0, 0, repeatAt)))));
              },
            );

            test(
              'repeat at 05:00 by 2 day.',
              () {
                const memId = 1;
                const repeatAt = (5 * 60) * 60;
                const repeatByNDay = 2;

                final oneLine = MemNotification.toOneLine(
                  [
                    MemNotification.repeated(memId).copiedWith(
                      time: () => repeatAt,
                    ),
                    MemNotification.repeatByNDay(memId).copiedWith(
                      time: () => repeatByNDay,
                    )
                  ],
                  (at) => fail("no call"),
                  buildRepeatEveryNDayNotificationText,
                  (at) => fail("no call"),
                  formatToTimeOfDay,
                );

                expect(
                    oneLine,
                    equals(buildRepeatEveryNDayNotificationText(
                        repeatByNDay.toString(),
                        formatToTimeOfDay(
                            DateAndTime(0, 0, 0, 0, 0, repeatAt)))));
              },
            );

            test(
              'repeat at 12:00 by 3 day on Mon.',
              () {
                const memId = 1;
                const repeatAt = (5 * 60) * 60;
                const repeatByNDay = 2;

                final oneLine = MemNotification.toOneLine(
                  [
                    MemNotification.repeated(memId).copiedWith(
                      time: () => repeatAt,
                    ),
                    MemNotification.repeatByNDay(memId).copiedWith(
                      time: () => repeatByNDay,
                    ),
                    MemNotification.repeatByDayOfWeek(memId, 0),
                  ],
                  (at) => fail("no call"),
                  buildRepeatEveryNDayNotificationText,
                  (at) => fail("no call"),
                  formatToTimeOfDay,
                );

                expect(
                    oneLine,
                    equals(
                      "${buildRepeatEveryNDayNotificationText(
                        repeatByNDay.toString(),
                        formatToTimeOfDay(
                          DateAndTime(0, 0, 0, 0, 0, repeatAt),
                        ),
                      )}, Mon",
                    ));
              },
            );
          },
        );

        test(
          'repeat by Tue.',
          () {
            const memId = 1;

            final oneLine = MemNotification.toOneLine(
              [MemNotification.repeatByDayOfWeek(memId, 1)],
              buildRepeatedNotificationText,
              (a, b) => "$a, $b",
              (a) => a,
              formatToTimeOfDay,
            );

            expect(oneLine, equals("Tue"));
          },
        );

        test(
          'after act',
          () {
            const memId = 1;
            const time = 2;
            final oneLine = MemNotification.toOneLine(
              [
                MemNotification.afterActStarted(memId).copiedWith(
                  time: () => time,
                )
              ],
              (a) => fail("no call"),
              (a, b) => fail("no call"),
              buildAfterActStartedNotificationText,
              formatToTimeOfDay,
            );

            expect(
                oneLine,
                buildAfterActStartedNotificationText(
                    DateFormat(DateFormat.HOUR24_MINUTE)
                        .format(DateAndTime(0, 0, 0, 0, 0, time))));
          },
        );
      },
    );
  });

  test('MemNotificationType from unexpected name throw.', () {
    const name = 'unexpected name';

    expect(
      () => MemNotificationType.fromName(name),
      throwsA(
        (e) {
          expect(e.message, 'Unexpected name: "$name".');
          return true;
        },
      ),
    );
  });
}
