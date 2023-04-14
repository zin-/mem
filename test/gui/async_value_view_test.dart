import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/gui/async_value_view.dart';

import '../_helpers.dart';

const testValue = 'test async value';
final testAsyncValueProvider = FutureProvider(
  (ref) => Future.value(testValue),
);

void main() {
  group('Appearance', () {
    setUp(() {});

    testWidgets(
      ': when asyncValue is loaded after loading',
      (widgetTester) async {
        await runTestWidget(
          widgetTester,
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) => AsyncValueView(
                ref.watch(testAsyncValueProvider),
                (String data) => Text(data),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text(testValue), findsNothing);

        await widgetTester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text(testValue), findsOneWidget);
      },
    );

    testWidgets(
      ': when asyncValue is something error',
      (widgetTester) async {
        const errorMessage = 'test error';

        await runTestWidget(
          widgetTester,
          ProviderScope(
            overrides: [
              testAsyncValueProvider.overrideWith((ref) {
                throw Exception(errorMessage);
              }),
            ],
            child: Consumer(
              builder: (context, ref, child) => AsyncValueView(
                ref.watch(testAsyncValueProvider),
                (String data) => Text(data),
              ),
            ),
          ),
        );

        expect(find.text('Exception: $errorMessage'), findsOneWidget);
        expect(find.text(testValue), findsNothing);
      },
    );
  });
}
