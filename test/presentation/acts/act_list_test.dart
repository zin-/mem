import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/list/act_list.dart';
import 'package:mem/features/acts/list/act_list_group.dart';
import 'package:mem/features/acts/list/item/total_act_time_item.dart';
import 'package:mem/features/acts/list/states.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/view/value_state_notifier.dart';

import '../../entity_factories.dart';

const _memId = 2;
const _memName = 'mem-a';
const _midnight = TimeOfDay(hour: 0, minute: 0);
const _fiveAm = TimeOfDay(hour: 5, minute: 0);

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
  required List<SavedActEntityV1> acts,
  required TimeOfDay startOfDay,
  Period group = Period.aDay,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferenceProvider(startOfDayKey).overrideWith(
          () => _FakePreference(startOfDay),
        ),
        dateViewProvider.overrideWith(
          (ref) => ValueStateNotifier(group),
        ),
        memEntitiesProvider.overrideWith(
          () => _FakeMemEntities([
            savedMem(id: _memId, name: _memName),
          ]),
        ),
        actListProvider(_memId).overrideWith((ref) => acts),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        home: Scaffold(
          body: ActList(_memId, null),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'hides actions for another day this month in date and time view',
    (tester) async {
      await _pumpActList(
        tester,
        acts: [_act(1, _anotherDayThisMonth())],
        startOfDay: _midnight,
      );

      expect(find.byType(TotalActTimeListItem), findsOneWidget);
      expect(find.text('1:00'), findsOneWidget);
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
      );

      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
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
      );

      expect(find.byIcon(Icons.calendar_view_day), findsOneWidget);
      expect(find.text('2026'), findsNothing);

      await tester.tap(find.byIcon(Icons.calendar_view_day));
      await tester.pumpAndSettle();

      for (final unit in ActListGroup.units) {
        expect(find.text(unit.name), findsOneWidget);
      }
      expect(find.text(Period.all.name), findsNothing);

      await tester.tap(find.text(Period.aYear.name));
      await tester.pumpAndSettle();

      expect(find.text('2026'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.calendar_view_day), findsNothing);
    },
  );
}
