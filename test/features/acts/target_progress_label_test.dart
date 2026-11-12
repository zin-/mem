import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act_amount.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/acts/target_progress_label.dart';
import 'package:mem/features/targets/target.dart';

void main() {
  const memId = 1;
  const count = 0;
  const targetValue = 5;

  Target goal({
    required TargetUnit unit,
    required int value,
    required Period period,
  }) =>
      Target(
        memId: memId,
        targetType: TargetType.equalTo,
        targetUnit: unit,
        value: value,
        period: period,
      );

  Future<void> pump(
    WidgetTester tester, {
    required ActAmount amount,
    required Target target,
    required Period shownIn,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TargetProgressLabel(
            amount,
            target,
            shownIn: shownIn,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the week mark on a day row', (tester) async {
    await pump(
      tester,
      amount: const ActAmount(count, Duration.zero),
      target: goal(
        unit: TargetUnit.count,
        value: targetValue,
        period: Period.aWeek,
      ),
      shownIn: Period.aDay,
    );

    expect(find.text('$count'), findsOneWidget);
    expect(find.text(' / '), findsNWidgets(2));
    expect(find.text('$targetValue'), findsOneWidget);
    expect(find.text('w'), findsOneWidget);
  });

  testWidgets('omits the period mark when the row matches the target',
      (tester) async {
    await pump(
      tester,
      amount: const ActAmount(count, Duration.zero),
      target: goal(
        unit: TargetUnit.count,
        value: targetValue,
        period: Period.aWeek,
      ),
      shownIn: Period.aWeek,
    );

    expect(find.text('$count'), findsOneWidget);
    expect(find.text(' / '), findsOneWidget);
    expect(find.text('$targetValue'), findsOneWidget);
    expect(find.text('w'), findsNothing);
  });

  testWidgets('shows recorded time over the time target', (tester) async {
    const recorded = Duration(minutes: 30);
    const targetLength = Duration(hours: 3);

    await pump(
      tester,
      amount: const ActAmount(count, recorded),
      target: goal(
        unit: TargetUnit.time,
        value: targetLength.inSeconds,
        period: Period.aDay,
      ),
      shownIn: Period.aDay,
    );

    expect(find.text('0:30'), findsOneWidget);
    expect(find.text(' / '), findsOneWidget);
    expect(find.text('3:00'), findsOneWidget);
  });
}
