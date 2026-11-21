import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/acts/list/act_list_view.dart';
import 'package:mem/features/acts/list/view.dart';
import 'package:mem/framework/date_and_time/duration_ext.dart';
import 'package:mem/features/acts/list/item/total_act_time_item.dart';
import 'package:mem/features/acts/list/item/view.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/widgets/infinite_scroll.dart';

import '../../entity_factories.dart';

const _memId = 2;
const _memName = 'mem-a';
const _midnight = TimeOfDay(hour: 0, minute: 0);
const _fiveAm = TimeOfDay(hour: 5, minute: 0);
// 時間。reloadShown 1回目の表示。1時間は 01 h 00 m
const _hoursOnFirstReload = 1;
// 時間。引き下げ（2回目）の表示。3回目はこれより長く、02 h 00 m は残らない
const _hoursOnRefresh = 2;

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _initial;

  _FakeMemEntities(this._initial);

  @override
  Iterable<MemEntity> build() => _initial;
}

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference(this.startOfDay);

  final TimeOfDay startOfDay;

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) => startOfDay;
}

class _ReloadShownActEntities extends ActEntities {
  int _reloadCount = 0;

  @override
  Future<void> reloadShown(int? memId) async {
    _reloadCount += 1;
    final hours = _reloadCount == 1
        ? _hoursOnFirstReload
        : _reloadCount == 2
            ? _hoursOnRefresh
            : _reloadCount;
    // upsert より先にしないと、actList が isUpdating false のまま再スケジュールする
    ref.read(isUpdating(memId).notifier).updatedBy(true);
    final start = DateTime(2026, 10, 13, 10);
    // 同じ id を置き換える。行が増えると時間が足されて回数と表示がずれる
    upsert([
      savedAct(
        id: 1,
        memId: memId ?? _memId,
        start: start,
        end: start.add(Duration(hours: hours)),
        createdAt: start,
      ),
    ]);
  }
}

DateTime _anotherDayThisMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day == 1 ? 2 : 1, 10);
}

SavedActEntityV1 _act(int id, DateTime start) => savedAct(
      id: id,
      memId: _memId,
      start: start,
      end: start.add(const Duration(hours: 1)),
      createdAt: start,
    );

Future<void> _pumpActList(
  WidgetTester tester, {
  List<SavedActEntityV1> acts = const [],
  required TimeOfDay startOfDay,
  Period group = Period.aDay,
  ActEntities? actEntities,
  ActListView? view,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferenceProvider(startOfDayKey).overrideWith(
          () => _FakePreference(startOfDay),
        ),
        memEntitiesProvider.overrideWith(
          () => _FakeMemEntities([
            savedMem(id: _memId, name: _memName),
          ]),
        ),
        if (actEntities != null)
          actEntitiesProvider.overrideWith(() => actEntities)
        else
          actListProvider(_memId).overrideWith((ref) => acts),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: ActList(
            _memId,
            null,
            groupUnit: group,
            view: view,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows each act when a mem is open and view is omitted',
    (tester) async {
      await _pumpActList(
        tester,
        acts: [_act(1, DateTime(2026, 10, 13, 10))],
        startOfDay: _midnight,
      );

      expect(find.byType(ActListItemView), findsOneWidget);
      expect(find.byType(TotalActTimeListItem), findsNothing);
    },
  );

  testWidgets(
    'hides actions for another day this month in date and time view',
    (tester) async {
      await _pumpActList(
        tester,
        acts: [_act(1, _anotherDayThisMonth())],
        startOfDay: _midnight,
        view: ActListView.totalTime,
      );

      expect(find.byType(TotalActTimeListItem), findsOneWidget);
      expect(
        find.text(const Duration(hours: 1).format()),
        // 小見出しと行が同じ合計を出す
        findsNWidgets(2),
      );
      expect(find.text(_memName), findsOneWidget);

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.leading, isNull);
      expect(tile.trailing, isNull);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.pause), findsNothing);
    },
  );

  testWidgets(
    'groups an act before start of day with the previous date',
    (tester) async {
      await _pumpActList(
        tester,
        acts: [
          _act(1, DateTime(2026, 10, 14, 3)),
          _act(2, DateTime(2026, 10, 13, 10)),
        ],
        startOfDay: _fiveAm,
        view: ActListView.totalTime,
      );

      expect(find.text('10/13/2026'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('10/14/2026'), findsNothing);
    },
  );

  testWidgets(
    'groups an act before start of day with the previous month',
    (tester) async {
      await _pumpActList(
        tester,
        acts: [
          _act(1, DateTime(2026, 11, 1, 3)),
          _act(2, DateTime(2026, 10, 31, 10)),
        ],
        startOfDay: _fiveAm,
        group: Period.aMonth,
        view: ActListView.totalTime,
      );

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('November 2026'), findsNothing);
    },
  );

  testWidgets(
    'groups an act before start of day with the previous week',
    (tester) async {
      await _pumpActList(
        tester,
        acts: [
          _act(1, DateTime(2026, 10, 12, 3)),
          _act(2, DateTime(2026, 10, 6, 10)),
        ],
        startOfDay: _fiveAm,
        group: Period.aWeek,
        view: ActListView.totalTime,
      );

      expect(find.text('10/05/2026 – 10/11/2026'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('10/12/2026 – 10/18/2026'), findsNothing);
    },
  );

  testWidgets(
    'groups an act before start of day with the previous quarter',
    (tester) async {
      await _pumpActList(
        tester,
        acts: [
          _act(1, DateTime(2026, 10, 1, 3)),
          _act(2, DateTime(2026, 8, 15, 10)),
        ],
        startOfDay: _fiveAm,
        group: Period.threeMonth,
        view: ActListView.totalTime,
      );

      expect(find.text('07/01/2026 – 09/30/2026'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('10/01/2026 – 12/31/2026'), findsNothing);
    },
  );

  testWidgets(
    'groups an act before start of day with the previous year',
    (tester) async {
      await _pumpActList(
        tester,
        acts: [
          _act(1, DateTime(2026, 1, 1, 3)),
          _act(2, DateTime(2025, 6, 15, 10)),
        ],
        startOfDay: _fiveAm,
        group: Period.aYear,
        view: ActListView.totalTime,
      );

      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('2026'), findsNothing);
    },
  );

  testWidgets(
    'groups acts from different years into one total',
    (tester) async {
      await _pumpActList(
        tester,
        acts: [
          _act(1, DateTime(2026, 6, 15, 10)),
          _act(2, DateTime(2025, 6, 15, 10)),
        ],
        startOfDay: _fiveAm,
        group: Period.all,
        view: ActListView.totalTime,
      );

      expect(find.text('all'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('2025'), findsNothing);
      expect(find.text('2026'), findsNothing);
    },
  );

  testWidgets(
    'selects a grouping unit from the menu',
    (tester) async {
      await _pumpActList(
        tester,
        acts: [_act(1, DateTime(2026, 10, 13, 10))],
        startOfDay: _midnight,
        view: ActListView.totalTime,
      );

      expect(find.byIcon(Icons.calendar_view_day), findsOneWidget);
      expect(find.text('2026'), findsNothing);

      await tester.tap(find.byIcon(Icons.calendar_view_day));
      await tester.pumpAndSettle();

      for (final unit in Period.values) {
        expect(find.text(unit.name), findsOneWidget);
      }

      await tester.tap(find.text(Period.aYear.name));
      await tester.pumpAndSettle();

      expect(find.text('2026'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.calendar_view_day), findsNothing);
    },
  );

  testWidgets(
    'pull to refresh reloads the shown act time',
    (tester) async {
      // px。中身が短くても overscroll して RefreshIndicator が走る
      const reloadFlingDistance = 300.0;
      // px/秒。引き下げとして扱われる速度
      const reloadFlingSpeed = 1000.0;
      // RefreshIndicator が閉じるまで。pumpAndSettle はインジケータが残ると終わらない
      const refreshIndicatorSettle = Duration(seconds: 1);

      await _pumpActList(
        tester,
        startOfDay: _midnight,
        actEntities: _ReloadShownActEntities(),
        view: ActListView.totalTime,
      );

      expect(
        find.text(const Duration(hours: _hoursOnFirstReload).format()),
        // 小見出しと行が同じ合計を出す
        findsNWidgets(2),
      );
      expect(
        find.text(const Duration(hours: _hoursOnRefresh).format()),
        findsNothing,
      );

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, reloadFlingDistance),
        reloadFlingSpeed,
      );
      await tester.pump();
      await tester.pump(refreshIndicatorSettle);
      await tester.pump(refreshIndicatorSettle);

      expect(
        find.text(const Duration(hours: _hoursOnRefresh).format()),
        // 小見出しと行が同じ合計を出す
        findsNWidgets(2),
      );
      expect(
        find.text(const Duration(hours: _hoursOnFirstReload).format()),
        findsNothing,
      );
    },
  );
}
