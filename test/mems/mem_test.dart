import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:test/test.dart';

void main() => group('Mem', () {
      final anchor = Act.by(
        1,
        startWhen: DateAndTime(2024, 10, 5, 12),
        endWhen: DateAndTime(2024, 10, 5, 12),
        completionKind: ActKind.finished,
      );

      test('done and undone preserve scheduleAnchorAct', () {
        final mem = Mem(
          1,
          'm',
          null,
          null,
          latestAct: anchor,
          scheduleAnchorAct: anchor,
        );

        expect(mem.done(DateTime(2024, 10, 12)).scheduleAnchorAct, same(anchor));
        expect(mem.undone().scheduleAnchorAct, same(anchor));
      });

      group('notifyAt', () {
        final startOfToday = DateTime(2024, 10, 12, 9, 0);

        test('uses period end when start is before today', () {
          final mem = Mem(
            1,
            'm',
            null,
            DateAndTimePeriod(
              start: DateAndTime(2024, 10, 10),
              end: DateAndTime(2024, 10, 15, 14, 30),
            ),
          );

          expect(
            mem.notifyAt(startOfToday, [], null),
            DateTime(2024, 10, 15, 14, 30),
          );
        });

        test('uses period start when start is on or after today', () {
          final mem = Mem(
            1,
            'm',
            null,
            DateAndTimePeriod(
              start: DateAndTime(2024, 10, 12, 10),
              end: DateAndTime(2024, 10, 15, 14, 30),
            ),
          );

          expect(
            mem.notifyAt(startOfToday, [], null),
            DateTime(2024, 10, 12, 10),
          );
        });

        test('uses period start when only start is set', () {
          final mem = Mem(
            1,
            'm',
            null,
            DateAndTimePeriod(start: DateAndTime(2024, 10, 15, 8)),
          );

          expect(
            mem.notifyAt(startOfToday, [], null),
            DateTime(2024, 10, 15, 8),
          );
        });

        test('prefers later of period and notification', () {
          final mem = Mem(
            1,
            'm',
            null,
            DateAndTimePeriod(end: DateAndTime(2024, 10, 20, 10)),
          );
          final notifications = [
            MemNotification.by(
              1,
              MemNotificationType.repeat,
              3600,
              'repeat at 01:00',
            ),
          ];

          expect(
            mem.notifyAt(startOfToday, notifications, null),
            DateTime(2024, 10, 20, 10),
          );
        });

        test('advances repeatByDayOfWeek past skip day', () {
          final skipDay = DateAndTime(2024, 10, 12, 12);
          final mem = Mem(
            1,
            'm',
            null,
            null,
            latestAct: Act.by(
              1,
              startWhen: skipDay,
              endWhen: skipDay,
              completionKind: ActKind.skipped,
            ),
          );
          final notifications = [
            MemNotification.by(
              1,
              MemNotificationType.repeatByDayOfWeek,
              6,
              'repeat on Sat',
            ),
          ];

          expect(
            mem.notifyAt(startOfToday, notifications, mem.latestAct),
            DateTime(2024, 10, 19, 9, 0),
          );
        });

        test('advances daily repeat past skip day', () {
          final skipDay = DateAndTime(2024, 10, 12, 12);
          final mem = Mem(
            1,
            'm',
            null,
            null,
            latestAct: Act.by(
              1,
              startWhen: skipDay,
              endWhen: skipDay,
              completionKind: ActKind.skipped,
            ),
          );
          final notifications = [
            MemNotification.by(
              1,
              MemNotificationType.repeat,
              3600 + 120,
              'repeat at 01:02',
            ),
          ];

          expect(
            mem.notifyAt(
              DateTime(2024, 10, 12),
              notifications,
              mem.latestAct,
            ),
            DateTime(2024, 10, 13, 1, 2),
          );
        });
      });
    });
