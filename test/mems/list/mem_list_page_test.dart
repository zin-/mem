import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/mem/list/actions.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/mems/list/actions.dart';
import 'package:mem/mems/list/page.dart';

void main() {
  setUpAll(() {
    DatabaseManager(onTest: true);
  });

  testWidgets('Hide & show ShowNewMemFab.', (widgetTester) async {
    final samples = List.generate(
      20,
      (index) => Mem(
        name: 'Hide & show ShowNewMemFab: mem name - $index',
        id: index,
      ),
    );

    await widgetTester.pumpWidget(ProviderScope(
      overrides: [
        fetchMemList.overrideWith((ref) => null),
        fetchActiveActs.overrideWith((ref) => Future.value(null)),
        activeActsProvider.overrideWith((ref) => ListValueStateNotifier([])),
        rawMemListProvider
            .overrideWith((ref) => ListValueStateNotifier(samples)),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => L10n(context).memDetailPageTitle(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: const MemListPage(),
      ),
    ));
    // await widgetTester.pumpAndSettle();

    expect(find.byIcon(Icons.add).hitTestable(), findsOneWidget);
    await widgetTester.drag(
      find.text(samples[5].name),
      const Offset(0, -100),
    );
    await widgetTester.pumpAndSettle();

    expect(find.byIcon(Icons.add).hitTestable(), findsNothing);

    await widgetTester.drag(
      find.text(samples[5].name),
      const Offset(0, 100),
    );
    await widgetTester.pumpAndSettle();

    expect(find.byIcon(Icons.add).hitTestable(), findsOneWidget);
  });
}
