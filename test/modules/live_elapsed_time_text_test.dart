import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/modules/live_elapsed_time_text.dart';

void main() {
  group('formatElapsedTime', () {
    test('< 1h as mm:ss', () {
      expect(
        formatElapsedTime(const Duration(minutes: 5, seconds: 3)),
        '05:03',
      );
    });

    test('1h to 24h as hh:mm', () {
      expect(
        formatElapsedTime(const Duration(hours: 1, minutes: 5)),
        '01:05',
      );
      expect(
        formatElapsedTime(const Duration(hours: 23, minutes: 59)),
        '23:59',
      );
    });

    test('>= 24h as {n}d hh', () {
      expect(
        formatElapsedTime(const Duration(hours: 24)),
        '1d 00',
      );
      expect(
        formatElapsedTime(const Duration(hours: 25)),
        '1d 01',
      );
    });
  });

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

    expect(longElapsed, startsWith('2d 00'));

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

    expect(shortElapsed, isNot(startsWith('2d 00')));
    expect(shortElapsed, matches(RegExp(r'^00:0[0-9]$')));
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
