import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/day_act_amount.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/list/item/total_act_time_item.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_view.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/mems/detail/page.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/modules/live_elapsed_time_text.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/generated/l10n/app_localizations.dart';

import '../../entity_factories.dart';

const _memId = 2;
const _memName = 'mem-a';

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _initial;

  _FakeMemEntities(this._initial);

  @override
  Iterable<MemEntity> build() => _initial;
}

class _FakeTargetState extends TargetState {
  @override
  Future<TargetEntityV1> build(int? memId) async => TargetEntityV1(
        Target(
          memId: memId,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: 1,
          period: Period.aDay,
        ),
      );
}

class _FakeMemRelationEntitiesByMemId extends MemRelationEntitiesByMemId {
  @override
  Future<Iterable<MemRelationEntityV1>> build(int? memId) async => [];
}

class _FakePreference extends Preference<TimeOfDay> {
  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 0, minute: 0);
}

class _FakeActEntities extends ActEntities {
  int startActbyCallCount = 0;
  int resumeActByCallCount = 0;
  int finishActbyCallCount = 0;
  int pauseByMemIdCallCount = 0;
  int closeByMemIdCallCount = 0;
  int? lastMemId;

  @override
  Iterable<SavedActEntityV1> build() => [];

  @override
  Future<void> startActby(int memId) async {
    startActbyCallCount++;
    lastMemId = memId;
  }

  @override
  Future<void> resumeActBy(int memId) async {
    resumeActByCallCount++;
    lastMemId = memId;
  }

  @override
  Future<void> finishActby(int memId) async {
    finishActbyCallCount++;
    lastMemId = memId;
  }

  @override
  Future<void> pauseByMemId(int memId) async {
    pauseByMemIdCallCount++;
    lastMemId = memId;
  }

  @override
  Future<void> closeByMemId(int memId) async {
    closeByMemIdCallCount++;
    lastMemId = memId;
  }
}

IconData _buttonIcon(Widget? button) =>
    ((button as IconButton).icon as Icon).icon!;

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _anotherDayThisMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day == 1 ? 2 : 1);
}

void main() {
  final mem = Mem(_memId, _memName, null, null);

  List<Override> overrides({
    Act? latestAct,
    _FakeActEntities? actEntities,
  }) =>
      [
        memEntitiesProvider.overrideWith(
          () => _FakeMemEntities([
            savedMem(id: _memId, name: _memName, latestAct: latestAct),
          ]),
        ),
        memNotificationsByMemIdProvider(_memId).overrideWith(
          (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
        ),
        memItemsByMemIdProvider(_memId).overrideWith(
          (ref) => ListValueStateNotifier<MemItemEntityV1>([]),
        ),
        targetStateProvider(_memId).overrideWith(() => _FakeTargetState()),
        memRelationEntitiesByMemIdProvider(_memId).overrideWith(
          () => _FakeMemRelationEntitiesByMemId(),
        ),
        preferenceProvider(startOfDayKey).overrideWith(() => _FakePreference()),
        if (actEntities != null)
          actEntitiesProvider.overrideWith(() => actEntities),
      ];

  Future<void> pumpItem(
    WidgetTester tester,
    Mem? mem, {
    DateTime? groupDate,
    bool isDateView = true,
    Act? latestAct,
    _FakeActEntities? actEntities,
    List<SavedActEntityV1>? acts,
    SavedTargetEntityV1? target,
    DayActAmount? dayAmount,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final resolvedGroupDate = groupDate ?? DateTime(2024, 6, 1);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...overrides(latestAct: latestAct, actEntities: actEntities),
          if (dayAmount != null)
            viewedDayActAmountProvider(
              _memId,
              DateTime(
                resolvedGroupDate.year,
                resolvedGroupDate.month,
                resolvedGroupDate.day,
              ),
            ).overrideWith((ref) async => dayAmount),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TotalActTimeListItem(
              acts ??
                  [
                    savedAct(
                      id: 1,
                      memId: _memId,
                      start: DateTime(2024, 6, 1, 10),
                      end: DateTime(2024, 6, 1, 11),
                      createdAt: DateTime(2024, 6, 1),
                    ),
                  ],
              mem,
              target,
              resolvedGroupDate,
              isDateView,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('TotalActTimeListItem', () {
    testWidgets('opens mem detail on tap and has no arrow', (tester) async {
      await pumpItem(tester, mem);

      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.text(_memName), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(MemDetailPage), findsOneWidget);
      expect(find.byKey(keyMemName), findsOneWidget);
      expect(find.text(_memName), findsOneWidget);
    });

    testWidgets('opens mem detail from act mem id when mem is omitted',
        (tester) async {
      await pumpItem(tester, null);

      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.text(_memName), findsNothing);

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(MemDetailPage), findsOneWidget);
      expect(find.text(_memName), findsOneWidget);
    });

    testWidgets('shows start and finish when latest act is absent',
        (tester) async {
      final acts = _FakeActEntities();
      await pumpItem(
        tester,
        mem,
        groupDate: _today(),
        actEntities: acts,
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(_buttonIcon(tile.leading), Icons.stop);
      expect(_buttonIcon(tile.trailing), Icons.play_arrow);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();
      expect(acts.finishActbyCallCount, 1);
      expect(acts.lastMemId, _memId);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(acts.startActbyCallCount, 1);
      expect(acts.lastMemId, _memId);
      expect(find.byType(MemDetailPage), findsNothing);
    });

    testWidgets('shows start and finish when latest act is finished',
        (tester) async {
      await pumpItem(
        tester,
        mem,
        groupDate: _today(),
        latestAct: FinishedAct(
          _memId,
          DateAndTime(2024, 6, 1, 10),
          DateAndTime(2024, 6, 1, 11),
        ),
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(_buttonIcon(tile.leading), Icons.stop);
      expect(_buttonIcon(tile.trailing), Icons.play_arrow);
    });

    testWidgets(
        'shows pause and finish while running even if started yesterday',
        (tester) async {
      final acts = _FakeActEntities();
      await pumpItem(
        tester,
        null,
        groupDate: _today(),
        latestAct: ActiveAct(_memId, DateAndTime(2026, 10, 20, 9)),
        actEntities: acts,
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(_buttonIcon(tile.leading), Icons.pause);
      expect(_buttonIcon(tile.trailing), Icons.stop);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      expect(acts.pauseByMemIdCallCount, 1);
      expect(acts.lastMemId, _memId);

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();
      expect(acts.finishActbyCallCount, 1);
      expect(acts.lastMemId, _memId);
    });

    testWidgets('shows resume and close while paused', (tester) async {
      final acts = _FakeActEntities();
      await pumpItem(
        tester,
        mem,
        groupDate: _today(),
        latestAct: PausedAct(_memId, DateTime(2026, 10, 20, 9)),
        actEntities: acts,
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(_buttonIcon(tile.leading), Icons.close);
      expect(_buttonIcon(tile.trailing), Icons.play_arrow);
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(acts.closeByMemIdCallCount, 1);
      expect(acts.lastMemId, _memId);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(acts.resumeActByCallCount, 1);
      expect(acts.lastMemId, _memId);
    });

    testWidgets('ignores an in-period active act when latest act is finished',
        (tester) async {
      await pumpItem(
        tester,
        mem,
        groupDate: _today(),
        latestAct: FinishedAct(
          _memId,
          DateAndTime(2024, 6, 1, 10),
          DateAndTime(2024, 6, 1, 11),
        ),
        acts: [
          savedAct(
            id: 1,
            memId: _memId,
            start: DateTime.now().subtract(const Duration(minutes: 5)),
            createdAt: DateTime.now(),
          ),
        ],
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(_buttonIcon(tile.leading), Icons.stop);
      expect(_buttonIcon(tile.trailing), Icons.play_arrow);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('hides actions on a past day and another day this month',
        (tester) async {
      final running = ActiveAct(_memId, DateAndTime(2026, 10, 20, 9));

      await pumpItem(
        tester,
        mem,
        groupDate: DateTime(2024, 6, 1),
        latestAct: running,
      );

      var tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.leading, isNull);
      expect(tile.trailing, isNull);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);

      await pumpItem(
        tester,
        mem,
        groupDate: _anotherDayThisMonth(),
        latestAct: running,
      );

      tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.leading, isNull);
      expect(tile.trailing, isNull);
    });

    testWidgets('shows actions for the current month outside date view',
        (tester) async {
      final now = DateTime.now();
      await pumpItem(
        tester,
        mem,
        groupDate: DateTime(now.year, now.month, 1),
        isDateView: false,
        latestAct: ActiveAct(_memId, DateAndTime(2026, 10, 20, 9)),
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(_buttonIcon(tile.leading), Icons.pause);
      expect(_buttonIcon(tile.trailing), Icons.stop);
    });

    testWidgets('hides actions for a past month outside date view',
        (tester) async {
      await pumpItem(
        tester,
        mem,
        groupDate: DateTime(2024, 6, 1),
        isDateView: false,
        latestAct: ActiveAct(_memId, DateAndTime(2026, 10, 20, 9)),
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.leading, isNull);
      expect(tile.trailing, isNull);
    });

    testWidgets('shows earliest start and latest end', (tester) async {
      final early = DateTime(2024, 6, 1, 9);
      final middle = DateTime(2024, 6, 1, 12);
      final late = DateTime(2024, 6, 1, 18, 30);
      await pumpItem(
        tester,
        mem,
        acts: [
          savedAct(
            id: 1,
            memId: _memId,
            start: middle,
            end: DateTime(2024, 6, 1, 13),
            createdAt: DateTime(2024, 6, 1),
          ),
          savedAct(
            id: 2,
            memId: _memId,
            start: early,
            end: DateTime(2024, 6, 1, 10),
            createdAt: DateTime(2024, 6, 1),
          ),
          savedAct(
            id: 3,
            memId: _memId,
            start: DateTime(2024, 6, 1, 15),
            end: late,
            actKind: ActKind.skipped,
            createdAt: DateTime(2024, 6, 1),
          ),
        ],
      );

      expect(find.text(_timeText(tester, early)), findsOneWidget);
      expect(find.text(_timeText(tester, late)), findsOneWidget);
      expect(find.text(_timeText(tester, middle)), findsNothing);
      expect(find.text(_dateText(tester, early)), findsNothing);
      expect(find.byType(DateAndTimeText), findsNWidgets(2));
    });

    testWidgets('shows start without end while one act is running',
        (tester) async {
      final start = DateTime(2024, 6, 1, 10);
      await pumpItem(
        tester,
        mem,
        acts: [
          savedAct(
            id: 1,
            memId: _memId,
            start: start,
            createdAt: DateTime(2024, 6, 1),
          ),
        ],
      );

      expect(find.text(_timeText(tester, start)), findsOneWidget);
      expect(find.text('~'), findsOneWidget);
      expect(find.byType(DateAndTimeText), findsOneWidget);
    });

    testWidgets('shows the running start after a finished act', (tester) async {
      final finishedStart = DateTime(2024, 6, 1, 9);
      final finishedEnd = DateTime(2024, 6, 1, 10);
      final runningStart = DateTime(2024, 6, 1, 16);
      await pumpItem(
        tester,
        mem,
        acts: [
          savedAct(
            id: 1,
            memId: _memId,
            start: finishedStart,
            end: finishedEnd,
            createdAt: DateTime(2024, 6, 1),
          ),
          savedAct(
            id: 2,
            memId: _memId,
            start: runningStart,
            createdAt: DateTime(2024, 6, 1),
          ),
        ],
      );

      expect(find.text(_timeText(tester, finishedStart)), findsOneWidget);
      expect(find.text(_timeText(tester, runningStart)), findsOneWidget);
      expect(find.text(_timeText(tester, finishedEnd)), findsNothing);
      expect(find.byType(DateAndTimeText), findsNWidgets(2));
    });

    testWidgets('shows dates outside date view', (tester) async {
      final start = DateTime(2024, 6, 2, 9);
      final end = DateTime(2024, 6, 20, 18, 30);
      await pumpItem(
        tester,
        mem,
        isDateView: false,
        groupDate: DateTime(2024, 6, 1),
        acts: [
          savedAct(
            id: 1,
            memId: _memId,
            start: start,
            end: end,
            createdAt: DateTime(2024, 6, 2),
          ),
        ],
      );

      expect(find.text(_timeText(tester, start)), findsOneWidget);
      expect(find.text(_timeText(tester, end)), findsOneWidget);
      expect(find.text(_dateText(tester, start)), findsOneWidget);
      expect(find.text(_dateText(tester, end)), findsOneWidget);
    });

    testWidgets('shows state time only on today in date view', (tester) async {
      final running = ActiveAct(_memId, DateAndTime(2026, 10, 20, 9));

      await pumpItem(
        tester,
        mem,
        groupDate: _today(),
        latestAct: running,
      );
      expect(find.byType(LiveElapsedTimeText), findsOneWidget);

      await pumpItem(
        tester,
        mem,
        groupDate: DateTime(2024, 6, 1),
        latestAct: running,
        acts: [
          savedAct(
            id: 1,
            memId: _memId,
            start: DateTime.now().subtract(const Duration(minutes: 30)),
            createdAt: DateTime.now(),
          ),
        ],
      );
      expect(find.byType(LiveElapsedTimeText), findsNothing);
      expect(find.text('0:30'), findsNothing);
      expect(find.text('0:00'), findsOneWidget);

      await pumpItem(
        tester,
        mem,
        groupDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        isDateView: false,
        latestAct: running,
      );
      expect(find.byType(LiveElapsedTimeText), findsNothing);
    });

    testWidgets('shows paused state time on today', (tester) async {
      await pumpItem(
        tester,
        mem,
        groupDate: _today(),
        latestAct: PausedAct(_memId, DateTime(2026, 10, 20, 9)),
      );

      expect(find.byType(LiveElapsedTimeText), findsOneWidget);
    });

    testWidgets('shows that day count beside the group total', (tester) async {
      await pumpItem(
        tester,
        mem,
        groupDate: DateTime(2024, 6, 1),
        target: _target(TargetUnit.count, 5),
        dayAmount: const DayActAmount(2, Duration.zero),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text(' / '), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byType(LiveElapsedTimeText), findsNothing);
    });

    testWidgets('shows that day recorded time over the time target',
        (tester) async {
      await pumpItem(
        tester,
        mem,
        groupDate: DateTime(2024, 6, 1),
        target: _target(TargetUnit.time, 3 * 60 * 60),
        dayAmount: const DayActAmount(1, Duration(minutes: 30)),
      );

      expect(find.text('0:30'), findsOneWidget);
      expect(find.text('3:00'), findsOneWidget);
      expect(find.text('1:00'), findsOneWidget);
    });

    testWidgets('keeps month totals without state time', (tester) async {
      await pumpItem(
        tester,
        mem,
        groupDate: DateTime(2024, 6, 1),
        isDateView: false,
        target: _target(TargetUnit.time, 3 * 60 * 60),
        latestAct: ActiveAct(_memId, DateAndTime(2026, 10, 20, 9)),
      );

      expect(find.byType(LiveElapsedTimeText), findsNothing);
      expect(find.text('1:00'), findsOneWidget);
      expect(find.text('3:00'), findsOneWidget);
      expect(find.text('0:30'), findsNothing);
    });
  });
}

SavedTargetEntityV1 _target(TargetUnit unit, int value) => SavedTargetEntityV1({
      'id': 1,
      'memId': _memId,
      'type': TargetType.equalTo.name,
      'unit': unit.name,
      'value': value,
      'period': Period.aMonth.name,
      'createdAt': DateTime(2024, 6, 1),
    });

String _timeText(WidgetTester tester, DateTime dateTime) =>
    TimeOfDay.fromDateTime(dateTime).format(
      tester.element(find.byType(TotalActTimeListItem)),
    );

String _dateText(WidgetTester tester, DateTime dateTime) =>
    MaterialLocalizations.of(
      tester.element(find.byType(TotalActTimeListItem)),
    ).formatCompactDate(dateTime);
