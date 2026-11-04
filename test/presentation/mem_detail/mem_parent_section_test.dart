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

    expect(find.text(_l10n.parentLabel), findsNothing);
    expect(find.text(_l10n.disconnectParentAction), findsNothing);
  });

  testWidgets('shows the saved parent name above relations', (tester) async {
    final child = await insertMem('Child');
    final parent = await insertMem('Parent');
    await MemRepository().receiveParent(
      MemParent(memId: child.id, parentMemId: parent.id),
    );

    await pumpDetail(tester, child.id);

    expect(find.text(_l10n.parentLabel), findsOneWidget);
    expect(find.text('Parent'), findsOneWidget);
    expect(find.text(_l10n.parentNone), findsNothing);
    expect(find.text(_l10n.disconnectParentAction), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(_l10n.parentLabel)).dy,
      lessThan(tester.getTopLeft(find.text('Relations')).dy),
    );
  });

  testWidgets('sets, replaces, and disconnects the parent', (tester) async {
    final child = await insertMem('Child');
    final parentA = await insertMem('Parent A');
    final parentB = await insertMem('Parent B');

    await pumpDetail(tester, child.id);

    expect(find.text(_l10n.parentLabel), findsOneWidget);
    expect(find.text(_l10n.parentNone), findsOneWidget);
    expect(find.text(_l10n.disconnectParentAction), findsNothing);

    await tester.tap(find.text(_l10n.parentLabel));
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
    expect(find.text(_l10n.disconnectParentAction), findsOneWidget);
    expect(
      (await MemRepository().shipParentByMemId(child.id))?.parentMemId,
      parentA.id,
    );

    await tester.tap(find.text(_l10n.parentLabel));
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

    await tester.tap(find.text(_l10n.disconnectParentAction));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.text('Parent B'), findsNothing);
    expect(find.text(_l10n.parentNone), findsOneWidget);
    expect(find.text(_l10n.disconnectParentAction), findsNothing);
    expect(await MemRepository().shipParentByMemId(child.id), isNull);
  });
}
