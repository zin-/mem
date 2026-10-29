import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_status_labels.dart';
import 'package:mem/features/acts/day_act_amount.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/modules/live_elapsed_time_text.dart';

void main() {
  const memId = 1;

  Target target({
    required TargetUnit unit,
    required int value,
  }) =>
      Target(
        memId: memId,
        targetType: TargetType.equalTo,
        targetUnit: unit,
        value: value,
        period: Period.aWeek,
      );

  Future<void> pump(
    WidgetTester tester, {
    Act? act,
    Target? goal,
    DayActAmount? amount,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActStatusLabels(act, goal, amount),
        ),
      ),
    );
  }

  testWidgets('hides state time unless active or paused', (tester) async {
    await pump(
      tester,
      act: FinishedAct(
        memId,
        DateAndTime(2026, 10, 30, 10),
        DateAndTime(2026, 10, 30, 11),
      ),
    );

    expect(find.byType(LiveElapsedTimeText), findsNothing);
    expect(find.text(' / '), findsNothing);
  });

  testWidgets('shows state time for active and paused', (tester) async {
    await pump(
      tester,
      act: ActiveAct(memId, DateAndTime(2026, 10, 30, 10)),
    );
    expect(find.byType(LiveElapsedTimeText), findsOneWidget);

    await pump(
      tester,
      act: PausedAct(memId, DateTime(2026, 10, 30, 10)),
    );
    expect(find.byType(LiveElapsedTimeText), findsOneWidget);
  });

  testWidgets('shows the day count beside state time', (tester) async {
    await pump(
      tester,
      act: ActiveAct(memId, DateAndTime(2026, 10, 30, 10)),
      goal: target(unit: TargetUnit.count, value: 4),
      amount: const DayActAmount(2, Duration.zero),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text(' / '), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.byType(LiveElapsedTimeText), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('2')).dx,
      lessThan(tester.getTopLeft(find.byType(LiveElapsedTimeText)).dx),
    );
  });

  testWidgets('hides a target whose value is 0', (tester) async {
    await pump(
      tester,
      goal: target(unit: TargetUnit.count, value: 0),
      amount: const DayActAmount(2, Duration.zero),
    );

    expect(find.text(' / '), findsNothing);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('shows recorded time over the time target', (tester) async {
    await pump(
      tester,
      goal: target(unit: TargetUnit.time, value: 2 * 60 * 60),
      amount: const DayActAmount(1, Duration(minutes: 30)),
    );

    expect(find.text('0:30'), findsOneWidget);
    expect(find.text(' / '), findsOneWidget);
    expect(find.text('2:00'), findsOneWidget);
    expect(find.byType(LiveElapsedTimeText), findsNothing);
  });

  testWidgets('adds running time and ignores paused time', (tester) async {
    final runningSince =
        DateTime.now().subtract(const Duration(minutes: 2, seconds: 30));
    await pump(
      tester,
      act: ActiveAct(
        memId,
        DateAndTime.from(runningSince, timeOfDay: runningSince),
      ),
      goal: target(unit: TargetUnit.time, value: 60 * 60),
      amount: const DayActAmount(1, Duration.zero),
    );

    expect(find.text('0:02'), findsOneWidget);
    expect(find.text('1:00'), findsOneWidget);
    expect(find.byType(LiveElapsedTimeText), findsOneWidget);

    await pump(
      tester,
      act: PausedAct(
        memId,
        DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      goal: target(unit: TargetUnit.time, value: 2 * 60 * 60),
      amount: const DayActAmount(1, Duration(hours: 1)),
    );

    expect(find.text('1:00'), findsOneWidget);
    expect(find.text('1:10'), findsNothing);
    expect(find.text('2:00'), findsOneWidget);
    expect(find.byType(LiveElapsedTimeText), findsOneWidget);
  });
}
