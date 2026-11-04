import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/databases/database.dart' hide Mem, MemParent;
import 'package:mem/features/logger/log.dart';
import 'package:mem/features/logger/log_repository.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mem_parents/mem_parent.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mems/detail/body.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers.mocks.dart';

final _l10n = lookupAppLocalizations(const Locale('ja'));

void main() {
  final mockedLoggerWrapper = MockLoggerWrapper();
  final mockedSentryWrapper = MockSentryWrapper();

  setUp(() {
    reset(mockedLoggerWrapper);
    reset(mockedSentryWrapper);
    when(mockedLoggerWrapper.log(any, any, any, any)).thenReturn(null);
    when(mockedSentryWrapper.captureException(any, any))
        .thenAnswer((_) async => 'test');

    LogRepository(mockedLoggerWrapper, mockedSentryWrapper);
    LogService(level: Level.info);

    SharedPreferences.setMockInitialValues({});
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(AppDatabase.memory()),
    );
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<MemRepository>();
    Singleton.reset<MemNotificationRepository>();
    Singleton.reset<MemRelationRepository>();
    Singleton.reset<TargetRepository>();
  });

  Future<MemEntity> insertMem(String name) =>
      MemRepository().receive(Mem(null, name, null, null));

  Future<void> pumpDetail(WidgetTester tester, int? memId) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Form(
              child: MemDetailBody(memId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );
  }

  testWidgets('hides the parent field on an unsaved mem', (tester) async {
    await pumpDetail(tester, null);

    expect(find.text(_l10n.parentNone), findsNothing);
    expect(find.byIcon(Icons.account_tree), findsNothing);
    expect(find.byIcon(Icons.subdirectory_arrow_right), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.text('親'), findsNothing);
    expect(find.text('子'), findsNothing);
  });

  testWidgets('shows the saved parent name above relations', (tester) async {
    final child = await insertMem('Child');
    final parent = await insertMem('Parent');
    await MemRepository().receiveParent(
      MemParent(memId: child.id, parentMemId: parent.id),
    );

    await pumpDetail(tester, child.id);

    expect(find.byIcon(Icons.account_tree), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);
    expect(find.text(_l10n.parentNone), findsNothing);
    expect(find.text('親'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Parent'),
        matching: find.byIcon(Icons.account_tree),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('Parent')).dy,
      lessThan(tester.getTopLeft(find.text('Relations')).dy),
    );
  });

  testWidgets('sets, replaces, and disconnects the parent', (tester) async {
    final child = await insertMem('Child');
    final parentA = await insertMem('Parent A');
    final parentB = await insertMem('Parent B');

    await pumpDetail(tester, child.id);

    expect(find.byIcon(Icons.account_tree), findsOneWidget);
    expect(find.text(_l10n.parentNone), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.tap(find.text(_l10n.parentNone));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    final dialog = find.byType(AlertDialog);
    expect(find.text(_l10n.selectParentTitle), findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Child')),
      findsNothing,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Parent A')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Parent B')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Parent A')),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.text('Parent A'), findsOneWidget);
    expect(find.text(_l10n.parentNone), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(
      (await MemRepository().shipParentByMemId(child.id))?.parentMemId,
      parentA.id,
    );

    await tester.tap(find.text('Parent A'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    await tester.tap(find.widgetWithText(ListTile, 'Parent B'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.text('Parent A'), findsNothing);
    expect(find.text('Parent B'), findsOneWidget);
    expect(
      (await MemRepository().shipParentByMemId(child.id))?.parentMemId,
      parentB.id,
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.text('Parent B'), findsNothing);
    expect(find.text(_l10n.parentNone), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(await MemRepository().shipParentByMemId(child.id), isNull);
  });

  testWidgets('shows direct child names in name order', (tester) async {
    final parent = await insertMem('Parent');
    final childB = await insertMem('Child B');
    final childA = await insertMem('Child A');
    final grandchild = await insertMem('Grandchild');
    await MemRepository().receiveParent(
      MemParent(memId: childB.id, parentMemId: parent.id),
    );
    await MemRepository().receiveParent(
      MemParent(memId: childA.id, parentMemId: parent.id),
    );
    await MemRepository().receiveParent(
      MemParent(memId: grandchild.id, parentMemId: childA.id),
    );

    await pumpDetail(tester, parent.id);

    expect(find.text('親'), findsNothing);
    expect(find.text('子'), findsNothing);
    expect(find.byIcon(Icons.subdirectory_arrow_right), findsNWidgets(2));
    expect(find.text('Child A'), findsOneWidget);
    expect(find.text('Child B'), findsOneWidget);
    expect(find.text('Grandchild'), findsNothing);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Child A'),
        matching: find.byIcon(Icons.subdirectory_arrow_right),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Child B'),
        matching: find.byIcon(Icons.subdirectory_arrow_right),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byIcon(Icons.account_tree)).dy,
      lessThan(tester.getTopLeft(find.text('Child A')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Child A')).dy,
      lessThan(tester.getTopLeft(find.text('Child B')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Child B')).dy,
      lessThan(tester.getTopLeft(find.text('Relations')).dy),
    );
  });

  testWidgets('hides the children field when a mem has no children',
      (tester) async {
    final mem = await insertMem('Alone');

    await pumpDetail(tester, mem.id);

    expect(find.byIcon(Icons.account_tree), findsOneWidget);
    expect(find.text(_l10n.parentNone), findsOneWidget);
    expect(find.byIcon(Icons.subdirectory_arrow_right), findsNothing);
    expect(find.text('親'), findsNothing);
    expect(find.text('子'), findsNothing);
  });

  testWidgets('hides self and descendants from the parent picker',
      (tester) async {
    final ancestor = await insertMem('Ancestor');
    final editing = await insertMem('Editing');
    final child = await insertMem('Child');
    final grandchild = await insertMem('Grandchild');
    await insertMem('Unrelated');
    await MemRepository().receiveParent(
      MemParent(memId: editing.id, parentMemId: ancestor.id),
    );
    await MemRepository().receiveParent(
      MemParent(memId: child.id, parentMemId: editing.id),
    );
    await MemRepository().receiveParent(
      MemParent(memId: grandchild.id, parentMemId: child.id),
    );

    await pumpDetail(tester, editing.id);

    await tester.tap(find.text('Ancestor'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    final dialog = find.byType(AlertDialog);
    expect(find.text(_l10n.selectParentTitle), findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Editing')),
      findsNothing,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Child')),
      findsNothing,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Grandchild')),
      findsNothing,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Ancestor')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Unrelated')),
      findsOneWidget,
    );
  });

  testWidgets('disables the current parent in the picker', (tester) async {
    final child = await insertMem('Child');
    final parent = await insertMem('Parent');
    final other = await insertMem('Other');
    await MemRepository().receiveParent(
      MemParent(memId: child.id, parentMemId: parent.id),
    );

    await pumpDetail(tester, child.id);

    await tester.tap(find.text('Parent'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    final dialog = find.byType(AlertDialog);
    final currentParentTile = find.descendant(
      of: dialog,
      matching: find.widgetWithText(ListTile, 'Parent'),
    );
    final otherTile = find.descendant(
      of: dialog,
      matching: find.widgetWithText(ListTile, 'Other'),
    );
    expect(currentParentTile, findsOneWidget);
    expect(tester.widget<ListTile>(currentParentTile).enabled, isFalse);
    expect(tester.widget<ListTile>(otherTile).enabled, isTrue);

    await tester.tap(currentParentTile);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      (await MemRepository().shipParentByMemId(child.id))?.parentMemId,
      parent.id,
    );

    await tester.tap(otherTile);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Parent'), findsNothing);
    expect(
      (await MemRepository().shipParentByMemId(child.id))?.parentMemId,
      other.id,
    );
  });
}
