import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/target_progress_label.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String? periodLabel,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TargetProgressLabel(
            current: '0',
            target: '5',
            periodLabel: periodLabel,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the period label after the progress', (tester) async {
    await pump(tester, periodLabel: 'w');

    expect(find.text('0'), findsOneWidget);
    expect(find.text(' / '), findsNWidgets(2));
    expect(find.text('5'), findsOneWidget);
    expect(find.text('w'), findsOneWidget);
  });

  testWidgets('omits the period label and its separator', (tester) async {
    await pump(tester);

    expect(find.text('0'), findsOneWidget);
    expect(find.text(' / '), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('w'), findsNothing);
  });
}
