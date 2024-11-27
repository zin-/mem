import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/mems/list/actions.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/list/widget.dart';
import 'package:mem/mems/list/show_new_mem_fab.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/mems/mem_entity.dart';

import '../../integration_test/scenarios/helpers.dart';

void main() {
  testWidgets('Hide & show ShowNewMemFab.', (widgetTester) async {
    final scrollController = ScrollController();
    final samples = List.generate(
      20,
      (index) => SavedMemEntity(
        'Hide & show ShowNewMemFab: mem name - $index',
        null,
        null,
      )
        ..id = index
        ..createdAt = zeroDate
        ..updatedAt = null
        ..archivedAt = null,
    );

    await widgetTester.pumpWidget(ProviderScope(
      overrides: [
        loadMemList.overrideWith((ref) => null),
        latestActsByMemProvider
            .overrideWith((ref) => ListValueStateNotifier([])),
        savedMemNotificationsProvider
            .overrideWith((ref) => ListValueStateNotifier([])),
        memsProvider.overrideWith((ref) => ListValueStateNotifier(samples)),
        memNotificationsByMemIdProvider
            .overrideWith((ref, arg) => ListValueStateNotifier([])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MemListWidget(scrollController),
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
