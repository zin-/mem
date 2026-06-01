import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mems/list/item/completion_dialog.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/l10n/l10n.dart';
import '../../helpers.dart' show buildTestApp;

void main() {
  group('completion_dialog', () {
    testWidgets('finish option calls onFinish', (tester) async {
      var finishCalled = false;
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showMemListCompletionDialog(
                context,
                onFinish: () => finishCalled = true,
                onSkip: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(buildL10n().memListCompletionDialogFinish));
      await tester.pumpAndSettle();

      expect(finishCalled, isTrue);
    });

    testWidgets('skip option calls onSkip', (tester) async {
      var skipCalled = false;
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showMemListCompletionDialog(
                context,
                onFinish: () {},
                onSkip: () => skipCalled = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(buildL10n().memListCompletionDialogSkip));
      await tester.pumpAndSettle();

      expect(skipCalled, isTrue);
    });

    testWidgets('cancel closes dialog without callbacks', (tester) async {
      var finishCalled = false;
      var skipCalled = false;
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showMemListCompletionDialog(
                context,
                onFinish: () => finishCalled = true,
                onSkip: () => skipCalled = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(buildL10n().cancelAction));
      await tester.pumpAndSettle();

      expect(finishCalled, isFalse);
      expect(skipCalled, isFalse);
    });

    testWidgets('memListCompletionStopButton long press when skip enabled', (
      tester,
    ) async {
      var dialogShown = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => memListCompletionStopButton(
                context: context,
                onFinish: () {},
                enableSkipMenu: true,
                onShowCompletionDialog: (_) => dialogShown = true,
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      expect(dialogShown, isTrue);
    });

    testWidgets('memListCompletionStopButton without skip menu', (tester) async {
      var dialogShown = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => memListCompletionStopButton(
                context: context,
                onFinish: () {},
                enableSkipMenu: false,
                onShowCompletionDialog: (_) => dialogShown = true,
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      expect(dialogShown, isFalse);
    });
  });
}
