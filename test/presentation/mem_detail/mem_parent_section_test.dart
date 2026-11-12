import 'dart:async';

import 'package:material_ui/material_ui.dart';
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
import 'package:mem/features/mems/detail/page.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers.mocks.dart';
import 'package:mem/l10n/l10n.dart';

final _l10n = lookupAppLocalizations(const Locale('ja'));

// メモリ DB は tap の中で完了する。mounted の return に入るには、その完了を画面を外すまで止める
class _PausedDatabase {
  Completer<void>? _release;
  Future<void>? _pending;

  Future<void> hold(WidgetTester tester) async {
    final release = Completer<void>();
    final entered = Completer<void>();
    _release = release;
    _pending = DriftDatabaseAccessor().driftDatabase.exclusively(() async {
      entered.complete();
      await release.future;
    });
    await tester.pump();
    await entered.future;
  }

  Future<void> release(WidgetTester tester) async {
    final release = _release;
    final pending = _pending;
    if (release == null || pending == null) return;
    _release = null;
    _pending = null;
    if (!release.isCompleted) release.complete();
    await pending;
    await tester.pump();
  }
}

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

  Future<MemEntity> insertMem(String name, {DateTime? doneAt}) =>
      MemRepository().receive(Mem(null, name, doneAt, null));

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );

  Future<void> confirmSelection(WidgetTester tester) async {
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(_l10n.okAction),
      ),
    );
  }

  MemEntity entity(ProviderContainer container, int id) =>
      container.read(memEntitiesProvider).singleWhere((mem) => mem.id == id);

  Future<ProviderContainer> pumpDetail(
    WidgetTester tester,
    int? memId, {
    Set<int>? parentIdsWithUndoneChildren,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        if (parentIdsWithUndoneChildren != null)
          parentMemIdsWithUndoneChildrenProvider.overrideWithValue(
            parentIdsWithUndoneChildren,
          ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Form(
              child: MemDetailBody(memId),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    return container;
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
      lessThan(tester.getTopLeft(find.text(_l10n.relationsTitle)).dy),
    );
  });

  testWidgets('sets, replaces, and disconnects the parent', (tester) async {
    final child = await insertMem('Child');
    final parentA = await insertMem('Parent A');
    final parentB = await insertMem('Parent B');

    final container = await pumpDetail(tester, child.id);

    expect(container.read(parentMemIdsWithUndoneChildrenProvider), isEmpty);
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
    await confirmSelection(tester);
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
    expect(
        container.read(parentMemIdsWithUndoneChildrenProvider), {parentA.id});

    await tester.tap(find.text('Parent A'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(MemDetailPage), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.text('Parent A'), findsNothing);
    expect(find.text(_l10n.parentNone), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(await MemRepository().shipParentByMemId(child.id), isNull);
    expect(container.read(parentMemIdsWithUndoneChildrenProvider), isEmpty);

    await tester.tap(find.text(_l10n.parentNone));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    await tester.tap(find.widgetWithText(ListTile, 'Parent B'));
    await confirmSelection(tester);
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
    expect(
        container.read(parentMemIdsWithUndoneChildrenProvider), {parentB.id});

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
    expect(container.read(parentMemIdsWithUndoneChildrenProvider), isEmpty);
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
      lessThan(tester.getTopLeft(find.text(_l10n.relationsTitle)).dy),
    );
  });

  testWidgets('removes only the disconnected child', (tester) async {
    final parent = await insertMem('Parent');
    final childA = await insertMem('Child A');
    final childB = await insertMem('Child B');
    await MemRepository().receiveParent(
      MemParent(memId: childA.id, parentMemId: parent.id),
    );
    await MemRepository().receiveParent(
      MemParent(memId: childB.id, parentMemId: parent.id),
    );

    await pumpDetail(tester, parent.id);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Child A'),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.text('Child A'), findsNothing);
    expect(find.text('Child B'), findsOneWidget);
    expect(find.byType(MemDetailPage), findsNothing);
    expect(await MemRepository().shipParentByMemId(childA.id), isNull);
    expect(
      (await MemRepository().shipParentByMemId(childB.id))?.parentMemId,
      parent.id,
    );
  });

  testWidgets('opens the child mem detail on tap', (tester) async {
    final parent = await insertMem('Parent');
    final child = await insertMem('Child');
    await MemRepository().receiveParent(
      MemParent(memId: child.id, parentMemId: parent.id),
    );

    await pumpDetail(tester, parent.id);

    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.byType(MemDetailPage), findsOneWidget);
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

    expect(find.byIcon(Icons.close), findsNWidgets(2));
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Ancestor'),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    await tester.tap(find.text(_l10n.parentNone));
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

  testWidgets('hides archived mems from the parent picker', (tester) async {
    final child = await insertMem('Child');
    await insertMem('Active');
    final archived = await insertMem('Archived');
    await MemRepository().replace(
      archived.updatedWith(
        archivedAt: () => DateTime(2024, 1, 1),
        items: () => null,
      ),
    );

    await pumpDetail(tester, child.id);

    await tester.tap(find.text(_l10n.parentNone));
    await settle(tester);

    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text('Active')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Archived')),
      findsNothing,
    );
  });

  testWidgets('leaves the parent unset when the picker is cancelled',
      (tester) async {
    final child = await insertMem('Child');
    await insertMem('Parent');

    await pumpDetail(tester, child.id);

    await tester.tap(find.text(_l10n.parentNone));
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(_l10n.cancelAction),
      ),
    );
    await settle(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(_l10n.parentNone), findsOneWidget);
    expect(await MemRepository().shipParentByMemId(child.id), isNull);
  });

  testWidgets('leaves the parent unset when nothing is chosen', (tester) async {
    final child = await insertMem('Child');
    await insertMem('Parent');

    await pumpDetail(tester, child.id);

    await tester.tap(find.text(_l10n.parentNone));
    await settle(tester);

    await confirmSelection(tester);
    await settle(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(_l10n.parentNone), findsOneWidget);
    expect(await MemRepository().shipParentByMemId(child.id), isNull);
  });

  testWidgets('keeps no parent when the chosen mem became a descendant',
      (tester) async {
    final editing = await insertMem('Editing');
    final child = await insertMem('Child');
    await insertMem('Unrelated');

    await pumpDetail(tester, editing.id);

    await tester.tap(find.text(_l10n.parentNone));
    await settle(tester);

    await MemRepository().receiveParent(
      MemParent(memId: child.id, parentMemId: editing.id),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Child'),
      ),
    );
    await confirmSelection(tester);
    await settle(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(_l10n.parentNone), findsOneWidget);
    expect(await MemRepository().shipParentByMemId(editing.id), isNull);
    expect(
      (await MemRepository().shipParentByMemId(child.id))?.parentMemId,
      editing.id,
    );
  });

  testWidgets('reloads the previous parent replaced from a stale detail',
      (tester) async {
    final child = await insertMem('Child');
    final previous = await insertMem('Previous');
    final next = await insertMem('Next');

    final container = await pumpDetail(tester, child.id);
    await MemRepository().receiveParent(
      MemParent(memId: child.id, parentMemId: previous.id),
    );
    await container.read(memEntitiesProvider.notifier).loadDetail(previous.id);
    await tester.pump();

    expect(find.text(_l10n.parentNone), findsOneWidget);
    expect(entity(container, previous.id).childMemIds, [child.id]);

    await tester.tap(find.text(_l10n.parentNone));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Next'),
      ),
    );
    await confirmSelection(tester);
    await settle(tester);

    expect(find.text('Next'), findsOneWidget);
    expect(
      (await MemRepository().shipParentByMemId(child.id))?.parentMemId,
      next.id,
    );
    expect(entity(container, previous.id).childMemIds, isEmpty);
  });

  testWidgets('does not open the parent picker after the detail is closed',
      (tester) async {
    final child = await insertMem('Child');
    await insertMem('Parent');
    await pumpDetail(tester, child.id);

    final paused = _PausedDatabase();
    try {
      await paused.hold(tester);
      await tester.tap(find.text(_l10n.parentNone));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      await paused.release(tester);
    }

    expect(find.byType(AlertDialog), findsNothing);
    expect(await MemRepository().shipParentByMemId(child.id), isNull);
  });

  testWidgets(
      'does not refresh parent details when the detail closes during save',
      (tester) async {
    final child = await insertMem('Child');
    final parent = await insertMem('Parent');
    final container = await pumpDetail(tester, child.id);

    await tester.tap(find.text(_l10n.parentNone));
    await settle(tester);

    final paused = _PausedDatabase();
    try {
      await paused.hold(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Parent'),
        ),
      );
      await confirmSelection(tester);
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      await paused.release(tester);
    }

    expect(
      (await MemRepository().shipParentByMemId(child.id))?.parentMemId,
      parent.id,
    );
    expect(entity(container, child.id).parentMemId, isNull);
  });

  testWidgets(
      'does not refresh parent details when the detail closes during disconnect',
      (tester) async {
    final child = await insertMem('Child');
    final parent = await insertMem('Parent');
    await MemRepository().receiveParent(
      MemParent(memId: child.id, parentMemId: parent.id),
    );
    final container = await pumpDetail(tester, child.id);

    final paused = _PausedDatabase();
    try {
      await paused.hold(tester);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      await paused.release(tester);
    }

    expect(await MemRepository().shipParentByMemId(child.id), isNull);
    expect(entity(container, child.id).parentMemId, parent.id);
  });

  testWidgets('disables the undone checkbox when the id is in the set',
      (tester) async {
    final parent = await insertMem('Parent');
    await pumpDetail(
      tester,
      parent.id,
      parentIdsWithUndoneChildren: {parent.id},
    );

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);
    expect(checkbox.onChanged, isNull);
  });

  testWidgets(
      'keeps undone available when the mem is done and the id is in the set',
      (tester) async {
    final parent = await insertMem('Parent', doneAt: DateTime.now());
    await pumpDetail(
      tester,
      parent.id,
      parentIdsWithUndoneChildren: {parent.id},
    );

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
    expect(checkbox.onChanged, isNotNull);

    checkbox.onChanged!(false);
    await tester.pump();

    final undone = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(undone.value, isFalse);
    expect(undone.onChanged, isNull);
  });

  testWidgets('keeps the checkbox when the id is not in the set',
      (tester) async {
    final parent = await insertMem('Parent');
    await pumpDetail(
      tester,
      parent.id,
      parentIdsWithUndoneChildren: {parent.id + 1},
    );

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);
    expect(checkbox.onChanged, isNotNull);

    checkbox.onChanged!(true);
    await tester.pump();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });
}
