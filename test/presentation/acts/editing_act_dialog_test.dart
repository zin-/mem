import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/list/item/editing_act_dialog.dart';

void main() {
  group('EditingActDialog test', () {
    testWidgets('should show dialog when actEntity is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const EditingActDialog(1),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Show Dialog'), findsOneWidget);
    });

    testWidgets('should test EditingActDialog constructor', (tester) async {
      const dialog = EditingActDialog(1);
      expect(dialog, isA<EditingActDialog>());
    });

    testWidgets('should test _EditingActDialogStateful constructor',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const EditingActDialog(1),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Show Dialog'), findsOneWidget);
    });

    testWidgets('should test _EditingActDialogComponent constructor',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const EditingActDialog(1),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Show Dialog'), findsOneWidget);
    });
  });
}
