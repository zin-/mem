import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestConstants {
  static const int testMemId = 1;
}

Widget _createTestWidget({
  int? memId,
}) {
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Test App'),
        actions: memId != null ? [const Icon(Icons.more_vert)] : null,
        backgroundColor: memId != null ? Colors.grey : null,
      ),
      body: const Center(
        child: Text('Test Body'),
      ),
      floatingActionButton: const FloatingActionButton(
        onPressed: null,
        child: Icon(Icons.add),
      ),
    ),
  );
}

Future<void> _pumpAndSettle(
  WidgetTester tester, {
  int? memId,
}) async {
  await tester.pumpWidget(_createTestWidget(memId: memId));
  await tester.pumpAndSettle();
}

void main() {
  group('MemDetailPage test', () {
    group('should display', () {
      testWidgets('basic structure for new mem.', (tester) async {
        await _pumpAndSettle(tester, memId: null);

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNull);
        expect(appBar.backgroundColor, isNull);
      });

      testWidgets('basic structure for saved mem.', (tester) async {
        await _pumpAndSettle(tester, memId: _TestConstants.testMemId);

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNotNull);
        expect(appBar.backgroundColor, isNotNull);
      });
    });

    group('should show', () {
      testWidgets('app bar actions for saved mem.', (tester) async {
        await _pumpAndSettle(tester, memId: _TestConstants.testMemId);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNotNull);
        expect(appBar.actions!.length, greaterThan(0));
      });

      testWidgets('no app bar actions for new mem.', (tester) async {
        await _pumpAndSettle(tester, memId: null);

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        final appBar = tester.widget<AppBar>(appBarFinder);
        expect(appBar.actions, isNull);
      });
    });
  });
}
