import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/count_reference_act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';

void main() {
  const startOfDay = TimeOfDay(hour: 5, minute: 0);
  final startOfToday =
      DateTime(2024, 10, 12, startOfDay.hour, startOfDay.minute);

  Act finished(DateTime end) {
    final at = DateAndTime.from(end, timeOfDay: end);
    return Act.by(
      1,
      startWhen: at.subtract(const Duration(minutes: 30)),
      endWhen: at,
    );
  }

  group('CountReferenceAct.of', () {
    test('returns null when there is no finished non-skipped act', () {
      expect(
        CountReferenceAct.of(latestAct: null),
        isNull,
      );
      expect(
        CountReferenceAct.of(
          latestAct: Act.by(
            1,
            startWhen: DateAndTime(2024, 10, 12, 10, 0),
          ),
        ),
        isNull,
      );
      expect(
        CountReferenceAct.of(
          latestAct: Act.by(
            1,
            startWhen: DateAndTime(2024, 10, 12, 9, 0),
            endWhen: DateAndTime(2024, 10, 12, 10, 0),
            completionKind: ActKind.skipped,
          ),
        ),
        isNull,
      );
    });

    test('prefers the latest finished act over the schedule anchor', () {
      final latest = finished(DateTime(2024, 10, 12, 10));
      final anchor = finished(DateTime(2024, 10, 10, 10));

      expect(
        CountReferenceAct.of(
          latestAct: latest,
          scheduleAnchorAct: anchor,
        )?.act,
        same(latest),
      );
    });

    test('uses a finished schedule anchor when the latest act cannot be used',
        () {
      final anchor = finished(DateTime(2024, 10, 10, 10));
      final skipped = Act.by(
        1,
        startWhen: DateAndTime(2024, 10, 12, 9),
        endWhen: DateAndTime(2024, 10, 12, 10),
        completionKind: ActKind.skipped,
      );
      final running = Act.by(
        1,
        startWhen: DateAndTime(2024, 10, 12, 11),
      );

      expect(
        CountReferenceAct.of(
          latestAct: skipped,
          scheduleAnchorAct: anchor,
        )?.act,
        same(anchor),
      );
      expect(
        CountReferenceAct.of(
          latestAct: running,
          scheduleAnchorAct: anchor,
        )?.act,
        same(anchor),
      );
      expect(
        CountReferenceAct.of(
          latestAct: null,
          scheduleAnchorAct: anchor,
        )?.act,
        same(anchor),
      );
    });
  });

  group('CountReferenceAct week window', () {
    test('week is the trailing aWeek ending on startOfToday', () {
      final reference = CountReferenceAct.of(
        latestAct: finished(DateTime(2024, 10, 10, 10)),
      )!;
      final expected = Period.aWeek.toPeriod(
        DateAndTime(
          startOfToday.year,
          startOfToday.month,
          startOfToday.day,
          startOfDay.hour,
          startOfDay.minute,
        ),
        startOfDay,
      )!;
      final week = reference.week(startOfToday, startOfDay);

      expect(week.start, expected.start);
      expect(week.end, expected.end);
    });

    test('isWithinWeek matches membership in week', () {
      final inWindow = CountReferenceAct.of(
        latestAct: finished(DateTime(2024, 10, 6, 10)),
      )!;
      final onBoundaryStart = CountReferenceAct.of(
        latestAct: finished(DateTime(2024, 10, 6, 5)),
      )!;
      final beforeWindow = CountReferenceAct.of(
        latestAct: finished(DateTime(2024, 10, 6, 4)),
      )!;
      final onToday = CountReferenceAct.of(
        latestAct: finished(DateTime(2024, 10, 12, 10)),
      )!;

      expect(inWindow.isWithinWeek(startOfToday, startOfDay), isTrue);
      expect(onBoundaryStart.isWithinWeek(startOfToday, startOfDay), isTrue);
      expect(beforeWindow.isWithinWeek(startOfToday, startOfDay), isFalse);
      expect(onToday.isWithinWeek(startOfToday, startOfDay), isTrue);

      expect(
        inWindow.week(startOfToday, startOfDay).includesStart(
              inWindow.act.period!.end!,
            ),
        inWindow.isWithinWeek(startOfToday, startOfDay),
      );
      expect(
        beforeWindow.week(startOfToday, startOfDay).includesStart(
              beforeWindow.act.period!.end!,
            ),
        beforeWindow.isWithinWeek(startOfToday, startOfDay),
      );
    });

    test('week does not follow the reference act day', () {
      final older = CountReferenceAct.of(
        latestAct: finished(DateTime(2024, 10, 8, 10)),
      )!;
      final newer = CountReferenceAct.of(
        latestAct: finished(DateTime(2024, 10, 11, 10)),
      )!;
      final olderWeek = older.week(startOfToday, startOfDay);
      final newerWeek = newer.week(startOfToday, startOfDay);

      expect(olderWeek.start, newerWeek.start);
      expect(olderWeek.end, newerWeek.end);
    });
  });
}
