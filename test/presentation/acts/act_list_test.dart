import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/list/act_list.dart';
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
  bool isDateView = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferenceProvider(startOfDayKey).overrideWith(
          () => _FakePreference(startOfDay),
        ),
        if (!isDateView)
          dateViewProvider.overrideWith(
            (ref) => ValueStateNotifier(false),
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
        isDateView: false,
      );

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('November 2026'), findsNothing);
    },
  );

  testWidgets(
    'shows actions on the previous day group before start of day',
    (tester) async {
      final now = DateTime.now();
      // 開始時刻ちょうどは当日の論理日になる。1分後なら前日が今日
      final boundary = now.add(const Duration(minutes: 1));
      final startOfDay =
          TimeOfDay(hour: boundary.hour, minute: boundary.minute);
      final yesterday = DateTime(
        now.year,
        now.month,
        now.day - 1,
        startOfDay.hour,
        startOfDay.minute,
      );

      await _pumpActList(
        tester,
        acts: [_act(1, yesterday)],
        startOfDay: startOfDay,
      );

      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(ActList)),
      );
      expect(
        find.text(localizations.formatCompactDate(yesterday)),
        findsOneWidget,
      );
      expect(find.text(localizations.formatCompactDate(now)), findsNothing);

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.leading, isNotNull);
      expect(tile.trailing, isNotNull);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    },
  );
}
