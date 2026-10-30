import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/targets/next_at_after_last_act.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:test/test.dart';

void main() {
  group('NextAtAfterLastAct', () {
    final end = DateAndTime(2026, 10, 30, 23, 30);
    const intervalSeconds = 2 * 60 * 60;
    final nextAt = end.add(const Duration(seconds: intervalSeconds));

    Target target({int? secondsAfterLastAct = intervalSeconds}) => Target(
          memId: 1,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: 4,
          period: Period.aDay,
          secondsAfterLastAct: secondsAfterLastAct,
        );

    Act finished({
      DateAndTime? endWhen,
      ActKind kind = ActKind.finished,
    }) =>
        Act.by(
          1,
          startWhen: DateAndTime(2026, 10, 30, 22),
          endWhen: endWhen ?? end,
          completionKind: kind,
        );

    test('adds the interval to the previous finished end', () {
      final earlier = Act.by(
        1,
        startWhen: DateAndTime(2026, 10, 29, 20),
        endWhen: DateAndTime(2026, 10, 29, 21),
      );

      expect(
        NextAtAfterLastAct.of(
          target: target(),
          latestAct: finished(),
          scheduleAnchorAct: earlier,
        )?.at,
        nextAt,
      );
    });

    test('uses the schedule anchor when the latest act is skipped', () {
      final anchorEnd = DateAndTime(2026, 10, 29, 21);
      final anchor = Act.by(
        1,
        startWhen: DateAndTime(2026, 10, 29, 20),
        endWhen: anchorEnd,
      );

      expect(
        NextAtAfterLastAct.of(
          target: target(),
          latestAct: finished(kind: ActKind.skipped),
          scheduleAnchorAct: anchor,
        )?.at,
        anchorEnd.add(const Duration(seconds: intervalSeconds)),
      );
      expect(
        NextAtAfterLastAct.of(
          target: target(),
          latestAct: finished(kind: ActKind.skipped),
        ),
        isNull,
      );
    });

    test('is absent while an act is running or paused, or none exists', () {
      expect(
        NextAtAfterLastAct.of(
          target: target(),
          latestAct: Act.by(1, startWhen: DateAndTime(2026, 10, 30, 9)),
          scheduleAnchorAct: finished(),
        ),
        isNull,
      );
      expect(
        NextAtAfterLastAct.of(
          target: target(),
          latestAct: Act.by(1, pausedAt: DateTime(2026, 10, 30, 9)),
          scheduleAnchorAct: finished(),
        ),
        isNull,
      );
      expect(
        NextAtAfterLastAct.of(target: target(), latestAct: null),
        isNull,
      );
    });

    test('is absent when the interval is unset', () {
      expect(
        NextAtAfterLastAct.of(
          target: target(secondsAfterLastAct: null),
          latestAct: finished(),
        ),
        isNull,
      );
    });
  });
}
