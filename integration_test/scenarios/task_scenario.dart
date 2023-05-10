import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    clearDatabase();
  });

  testTaskScenario();
}

void testTaskScenario() => group(
      'Task scenario',
      () {
        testWidgets(
          ': Set Period.',
          (widgetTester) async {
            final now = DateTime.now();

            await app.main();
            await widgetTester.pumpAndSettle();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(newMemFabFinder);
            await widgetTester.pumpAndSettle();

            expect(find.text('M/d/y'), findsNWidgets(2));
            expect(calendarIconFinder, findsNWidgets(2));
            expect(switchFinder, findsNWidgets(2));
            expect(timeIconFinder, findsNothing);
            await widgetTester.tap(calendarIconFinder.at(0));
            await widgetTester.pumpAndSettle();

            const selectDate = 2;
            await widgetTester.tap(find.text('$selectDate'));
            await widgetTester.tap(find.text('OK'));
            await widgetTester.pumpAndSettle();
            expect(
              find.text('${now.month}/$selectDate/${now.year}'),
              findsOneWidget,
            );
            // TODO fix DateAndTimeTextFormField
            expect(timeIconFinder, findsNothing);

            await widgetTester.tap(switchFinder.at(0));
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.text('OK'));
            await widgetTester.pumpAndSettle();
            final hour = now.hour > 12 ? now.hour - 12 : now.hour;
            expect(
              find.text('$hour:${now.minute} ${now.hour > 12 ? 'PM' : 'AM'}'),
              findsOneWidget,
            );
            expect(timeIconFinder, findsOneWidget);

            expect(1, 1);
          },
        );
      },
    );

final newMemFabFinder = find.byIcon(Icons.add);
final calendarIconFinder = find.byIcon(Icons.calendar_month);
final switchFinder = find.byType(Switch);
final timeIconFinder = find.byIcon(Icons.access_time_outlined);
