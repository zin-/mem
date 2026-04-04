import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/modules/live_elapsed_time_text.dart';

void main() {
  testWidgets(
      'when start changes, elapsed display uses new start immediately',
      (WidgetTester tester) async {
    final key = GlobalKey();
    final longAgo = DateTime.now().subtract(const Duration(hours: 48));
    final shortAgo = DateTime.now().subtract(const Duration(seconds: 8));

    await tester.pumpWidget(
      MaterialApp(
        home: _StartController(
          key: key,
          start: longAgo,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    final longElapsed = tester
        .widget<Text>(
          find.descendant(
            of: find.byType(LiveElapsedTimeText),
            matching: find.byType(Text),
          ),
        )
        .data!;

    expect(longElapsed, startsWith('48:'));

    await tester.pumpWidget(
      MaterialApp(
        home: _StartController(
          key: key,
          start: shortAgo,
        ),
      ),
    );
    await tester.pump();

    final shortElapsed = tester
        .widget<Text>(
          find.descendant(
            of: find.byType(LiveElapsedTimeText),
            matching: find.byType(Text),
          ),
        )
        .data!;

    expect(shortElapsed, isNot(startsWith('48:')));
    expect(shortElapsed, matches(RegExp(r'^0{1,2}:00:0[0-9]$')));
  });
}

class _StartController extends StatefulWidget {
  const _StartController({super.key, required this.start});

  final DateTime start;

  @override
  State<_StartController> createState() => _StartControllerState();
}

class _StartControllerState extends State<_StartController> {
  @override
  Widget build(BuildContext context) => LiveElapsedTimeText(widget.start);
}
