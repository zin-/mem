import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/mem/list/actions.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/mems/list/actions.dart';
import 'package:mem/mems/list/body.dart';
import 'package:mem/mems/list/show_new_mem_fab.dart';
import 'package:mem/mems/states.dart';

void main() {
  setUpAll(() {
    DatabaseManager(onTest: true);
  });

  testWidgets('Hide & show ShowNewMemFab.', (widgetTester) async {
    final scrollController = ScrollController();
    final samples = List.generate(
      20,
      (index) => Mem(
        name: 'Hide & show ShowNewMemFab: mem name - $index',
        id: index,
      ),
    );

    await widgetTester.pumpWidget(ProviderScope(
      overrides: [
        loadMemList.overrideWith((ref) => null),
        fetchActiveActs.overrideWith((ref) => Future.value(null)),
        fetchMemNotifications.overrideWith((ref, arg) => Future(() => [])),
        activeActsProvider.overrideWith((ref) => ListValueStateNotifier([])),
        memsProvider.overrideWith((ref) => ListValueStateNotifier(samples)),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => buildL10n(context).memDetailPageTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MemListBody(scrollController),
          floatingActionButton: ShowNewMemFab(scrollController),
        ),
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
