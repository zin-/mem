import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/atoms/async_value_view.dart';

import '../helpers.dart';

void main() {
  Logger(level: Level.verbose);

  testWidgets(
    'new',
    (widgetTester) async {
      await widgetTester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                return AsyncValueView(
                  ref.watch(testAsyncValueProvider),
                  (String value) => Text(value),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await widgetTester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('test value'), findsOneWidget);
    },
    tags: TestSize.small,
  );

  testWidgets(
    'error',
    (widgetTester) async {
      await widgetTester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                return AsyncValueView(
                  ref.watch(errorAsyncValueProvider),
                  (String value) => Text(value),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await widgetTester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('test value'), findsNothing);

      // FIXME なぜ表示されないんだろう？
      // expect(find.text('Exception test error'), findsOneWidget);
    },
    tags: TestSize.small,
  );
}

final testAsyncValueProvider = FutureProvider((ref) async => 'test value');
final errorAsyncValueProvider = FutureProvider(
  (ref) async => throw Exception('test error'),
);
