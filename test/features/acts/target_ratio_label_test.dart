import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/list/target_period_mark.dart';
import 'package:mem/features/acts/target_ratio_label.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    TargetPeriodMark? mark,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TargetRatioLabel(
            current: '0',
            target: '5',
            mark: mark,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the mark after the ratio', (tester) async {
    await pump(
      tester,
      mark: TargetPeriodMark.of(
        group: Period.aDay,
        target: Period.aWeek,
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text(' / '), findsNWidgets(2));
    expect(find.text('5'), findsOneWidget);
    expect(find.text('w'), findsOneWidget);
  });

  testWidgets('omits the mark and its separator', (tester) async {
    await pump(tester);

    expect(find.text('0'), findsOneWidget);
    expect(find.text(' / '), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('w'), findsNothing);
  });
}
