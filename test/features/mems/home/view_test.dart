import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/home/habitual_mems.dart';
import 'package:mem/features/mems/home/mems_by_notify_at.dart';
import 'package:mem/features/mems/home/overdue_mems.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/home_screen.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/values/colors.dart';

import '../../../entity_factories.dart';

// 1回目は表示前の loadMemList。2回目が引き下げ
const _reloadLoadCount = 2;
const _reloadedNameSuffix = ' reloaded';

// view は memEntities のフェイクで描く。本番の overdue は DB 候補取得
Future<List<MemEntity>> _overdueFromMemEntities(Ref ref) async {
  final mems = ref.watch(memEntitiesProvider);
  final notifications = ref.watch(savedMemNotificationsProvider);
  final startOfToday = DateTimeExt.startOfToday(
    ref.watch(preferenceProvider(startOfDayKey)),
  );
  return MemsByNotifyAt.of(
    mems,
    notifications,
    startOfToday: startOfToday,
    periodCountByMemId: const {},
    include: (notifyAt) => notifyAt.isBefore(DateTime.now()),
  ).mems;
}

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _state;
  final void Function()? _onLoad;
  final bool _renameOnReload;
  var _loadCount = 0;

  _FakeMemEntities(
    this._state, {
    void Function()? onLoad,
    bool renameOnReload = false,
  })  : _onLoad = onLoad,
        _renameOnReload = renameOnReload;

  @override
  Iterable<MemEntity> build() => _state;

  @override
  Future<void> loadMemList({bool? archived, bool? done}) async {
    _onLoad?.call();
    if (!_renameOnReload) return;

    _loadCount += 1;
    if (_loadCount < _reloadLoadCount) return;

    // loadMemListProvider の build 中に state を更新すると Riverpod が拒否する
    await Future<void>.value();
    state = [
      for (final mem in state)
        mem.updatedWith(
          update: (current) => Mem(
            current.id,
            '${current.name}$_reloadedNameSuffix',
            current.doneAt,
            current.period,
            latestAct: current.latestAct,
            scheduleAnchorAct: current.scheduleAnchorAct,
          ),
        ),
    ];
  }
}

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 9, minute: 0);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  final createdAt = DateTime(2024, 6, 1);

  MemEntity at(int id, DateTime when) => savedMem(
        id: id,
        name: 'Mem $id',
        createdAt: createdAt,
        updatedAt: createdAt,
        notifyOn: when,
        notifyAt: when,
      );

  HabitualMem habitualMem(
    MemEntity mem, {
    Duration sameWeekdayTime = const Duration(minutes: 1),
    int sameWeekdayCount = 1,
    Duration totalTime = const Duration(minutes: 1),
    int totalCount = 1,
  }) =>
      HabitualMem.of(
        mem,
        HabitualRank.of(
          sameWeekdayTime: sameWeekdayTime,
          sameWeekdayCount: sameWeekdayCount,
          totalTime: totalTime,
          totalCount: totalCount,
        ),
      );

  testWidgets(
    'Home is selected first and shows at most three upcoming mems',
    (tester) async {
      final mems = [
        at(1, DateTime(2099, 1, 3, 10)),
        at(2, DateTime(2099, 1, 1, 10)),
        at(3, DateTime(2099, 1, 4, 10)),
        at(4, DateTime(2099, 1, 2, 10)),
      ];
      var loadCount = 0;
      final memEntities = _FakeMemEntities(
        mems,
        onLoad: () => loadCount += 1,
      );
      final l10n = buildL10n();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
            memEntitiesProvider.overrideWith(() => memEntities),
            savedMemNotificationsProvider.overrideWith(
              (ref) => ListValueStateNotifier<SavedMemNotificationEntityV1>([]),
            ),
            for (final mem in mems)
              memNotificationsByMemIdProvider(mem.id).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
            overdueMemsProvider.overrideWith(_overdueFromMemEntities),
            habitualMemsProvider.overrideWith((ref) async => <HabitualMem>[]),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(loadCount, greaterThan(0));
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text(l10n.homeDestinationLabel), findsOneWidget);
      expect(find.text(l10n.memListDestinationLabel), findsOneWidget);
      expect(find.text(l10n.actListDestinationLabel), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .whereType<String>()
            .where((data) => data.startsWith('Mem '))
            .toList(),
        ['Mem 2', 'Mem 4', 'Mem 1'],
      );
      expect(find.byType(Card), findsOneWidget);
      for (final name in ['Mem 2', 'Mem 4', 'Mem 1']) {
        expect(
          find.descendant(of: find.byType(Card), matching: find.text(name)),
          findsOneWidget,
        );
      }

      await tester.tap(find.text(l10n.memListDestinationLabel));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Mem 3'), findsOneWidget);
    },
  );

  testWidgets(
    'shows overdue mems above at most three upcoming mems',
    (tester) async {
      final mems = [
        at(1, DateTime(2099, 1, 3, 10)),
        at(2, DateTime(2099, 1, 1, 10)),
        at(3, DateTime(2099, 1, 4, 10)),
        at(4, DateTime(2099, 1, 2, 10)),
        at(20, DateTime(2020, 1, 1, 10)),
        at(21, DateTime(2020, 1, 2, 10)),
        at(22, DateTime(2020, 1, 3, 10)),
        at(23, DateTime(2020, 1, 4, 10)),
      ];
      final memEntities = _FakeMemEntities(mems);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
            memEntitiesProvider.overrideWith(() => memEntities),
            savedMemNotificationsProvider.overrideWith(
              (ref) => ListValueStateNotifier<SavedMemNotificationEntityV1>([]),
            ),
            for (final mem in mems)
              memNotificationsByMemIdProvider(mem.id).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
            overdueMemsProvider.overrideWith(_overdueFromMemEntities),
            habitualMemsProvider.overrideWith((ref) async => <HabitualMem>[]),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .whereType<String>()
            .where((data) => data.startsWith('Mem '))
            .toList(),
        [
          'Mem 20',
          'Mem 21',
          'Mem 22',
          'Mem 23',
          'Mem 2',
          'Mem 4',
          'Mem 1',
        ],
      );

      expect(find.byType(Card), findsNWidgets(2));

      Card cardOf(String name) => tester.widget<Card>(
            find.ancestor(
              of: find.text(name),
              matching: find.byType(Card),
            ),
          );

      final overdueCard = cardOf('Mem 20');
      expect(
        overdueCard.color,
        warningSurfaceOn(
          Theme.of(tester.element(find.byWidget(overdueCard)))
              .colorScheme
              .surface,
        ),
      );
      final upcomingCard = cardOf('Mem 2');
      expect(upcomingCard, isNot(same(overdueCard)));
      expect(upcomingCard.color, isNull);

      EdgeInsets resolved(EdgeInsetsGeometry insets) =>
          insets.resolve(TextDirection.ltr);

      final listPadding = resolved(
        tester
                .widget<ListView>(
                  find.ancestor(
                    of: find.byWidget(overdueCard),
                    matching: find.byType(ListView),
                  ),
                )
                .padding ??
            EdgeInsets.zero,
      );
      final overdueMargin = resolved(overdueCard.margin!);
      final upcomingMargin = resolved(upcomingCard.margin!);

      void expectPageEdgeMargin(EdgeInsets margin) {
        expect(margin.left, 16);
        expect(margin.right, 16);
      }

      expect(overdueMargin.bottom + upcomingMargin.top, 8);
      expectPageEdgeMargin(overdueMargin);
      expectPageEdgeMargin(upcomingMargin);
      expect(listPadding.top + overdueMargin.top, 16);
      expect(listPadding.bottom + upcomingMargin.bottom, 16);

      ListTile tileOf(String name) => tester.widget<ListTile>(
            find.ancestor(
              of: find.text(name),
              matching: find.byType(ListTile),
            ),
          );

      for (final name in ['Mem 20', 'Mem 21', 'Mem 22', 'Mem 23']) {
        expect(cardOf(name), same(overdueCard));
        expect(tileOf(name).tileColor, isNull);
      }
      for (final name in ['Mem 2', 'Mem 4', 'Mem 1']) {
        expect(cardOf(name), same(upcomingCard));
        expect(tileOf(name).tileColor, isNull);
      }
    },
  );

  testWidgets(
    'shows an often-this-hour card without mems already on overdue or upcoming',
    (tester) async {
      final overdueEarly = at(20, DateTime(2020, 1, 1, 10));
      final overdueLate = at(21, DateTime(2020, 1, 2, 10));
      final upcomingFirst = at(2, DateTime(2099, 1, 1, 10));
      final upcomingSecond = at(4, DateTime(2099, 1, 2, 10));
      final upcomingThird = at(1, DateTime(2099, 1, 3, 10));
      final upcomingFourth = at(3, DateTime(2099, 1, 4, 10));
      final onlyHabitual = savedMem(
        id: 30,
        name: 'Mem 30',
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final mems = [
        upcomingThird,
        upcomingFirst,
        upcomingFourth,
        upcomingSecond,
        overdueEarly,
        overdueLate,
        onlyHabitual,
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities(mems)),
            savedMemNotificationsProvider.overrideWith(
              (ref) => ListValueStateNotifier<SavedMemNotificationEntityV1>([]),
            ),
            for (final mem in mems)
              memNotificationsByMemIdProvider(mem.id).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
            overdueMemsProvider.overrideWith(_overdueFromMemEntities),
            habitualMemsProvider.overrideWith(
              (ref) async => [
                habitualMem(overdueEarly),
                habitualMem(upcomingFirst),
                habitualMem(onlyHabitual),
                habitualMem(upcomingFourth),
              ],
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .whereType<String>()
            .where((data) => data.startsWith('Mem '))
            .toList(),
        [
          'Mem 20',
          'Mem 21',
          'Mem 2',
          'Mem 4',
          'Mem 1',
          'Mem 30',
          'Mem 3',
        ],
      );
      expect(find.byType(Card), findsNWidgets(3));
      expect(find.byIcon(Icons.schedule), findsOneWidget);

      final habitualCard = find.ancestor(
        of: find.byIcon(Icons.schedule),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: habitualCard, matching: find.text('Mem 30')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: habitualCard, matching: find.text('Mem 3')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: habitualCard, matching: find.text('Mem 20')),
        findsNothing,
      );
      expect(
        find.descendant(of: habitualCard, matching: find.text('Mem 2')),
        findsNothing,
      );
      expect(find.text('Mem 20'), findsOneWidget);
      expect(find.text('Mem 2'), findsOneWidget);
    },
  );

  testWidgets(
    'shows only the next three habitual mems after excluding the overdue one',
    (tester) async {
      final overdue = at(20, DateTime(2020, 1, 1, 10));
      MemEntity habitualOnly(int id) => savedMem(
            id: id,
            name: 'Mem $id',
            createdAt: createdAt,
            updatedAt: createdAt,
          );
      final second = habitualOnly(31);
      final third = habitualOnly(32);
      final fourth = habitualOnly(33);
      final fifth = habitualOnly(34);
      final mems = [overdue, second, third, fourth, fifth];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities(mems)),
            savedMemNotificationsProvider.overrideWith(
              (ref) => ListValueStateNotifier<SavedMemNotificationEntityV1>([]),
            ),
            for (final mem in mems)
              memNotificationsByMemIdProvider(mem.id).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
            overdueMemsProvider.overrideWith(_overdueFromMemEntities),
            habitualMemsProvider.overrideWith(
              (ref) async => [
                habitualMem(overdue),
                habitualMem(second),
                habitualMem(third),
                habitualMem(fourth),
                habitualMem(fifth),
              ],
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .whereType<String>()
            .where((data) => data.startsWith('Mem '))
            .toList(),
        ['Mem 20', 'Mem 31', 'Mem 32', 'Mem 33'],
      );

      final habitualCard = find.ancestor(
        of: find.byIcon(Icons.schedule),
        matching: find.byType(Card),
      );
      for (final name in ['Mem 31', 'Mem 32', 'Mem 33']) {
        expect(
          find.descendant(of: habitualCard, matching: find.text(name)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: habitualCard, matching: find.text('Mem 20')),
        findsNothing,
      );
      expect(
        find.descendant(of: habitualCard, matching: find.text('Mem 34')),
        findsNothing,
      );
      expect(find.text('Mem 34'), findsNothing);
      expect(find.text('Mem 20'), findsOneWidget);
    },
  );

  testWidgets(
    'shows only the next two habitual mems after excluding the overdue one when the count setting is 2',
    (tester) async {
      final overdue = at(20, DateTime(2020, 1, 1, 10));
      MemEntity habitualOnly(int id) => savedMem(
            id: id,
            name: 'Mem $id',
            createdAt: createdAt,
            updatedAt: createdAt,
          );
      final second = habitualOnly(31);
      final third = habitualOnly(32);
      final fourth = habitualOnly(33);
      final fifth = habitualOnly(34);
      final mems = [overdue, second, third, fourth, fifth];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
            preferenceProvider(habitualMemsCountKey).overrideWithValue(2),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities(mems)),
            savedMemNotificationsProvider.overrideWith(
              (ref) => ListValueStateNotifier<SavedMemNotificationEntityV1>([]),
            ),
            for (final mem in mems)
              memNotificationsByMemIdProvider(mem.id).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
            overdueMemsProvider.overrideWith(_overdueFromMemEntities),
            habitualMemsProvider.overrideWith(
              (ref) async => [
                habitualMem(overdue),
                habitualMem(second),
                habitualMem(third),
                habitualMem(fourth),
                habitualMem(fifth),
              ],
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .whereType<String>()
            .where((data) => data.startsWith('Mem '))
            .toList(),
        ['Mem 20', 'Mem 31', 'Mem 32'],
      );

      final habitualCard = find.ancestor(
        of: find.byIcon(Icons.schedule),
        matching: find.byType(Card),
      );
      for (final name in ['Mem 31', 'Mem 32']) {
        expect(
          find.descendant(of: habitualCard, matching: find.text(name)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: habitualCard, matching: find.text('Mem 20')),
        findsNothing,
      );
      expect(
        find.descendant(of: habitualCard, matching: find.text('Mem 33')),
        findsNothing,
      );
      expect(
        find.descendant(of: habitualCard, matching: find.text('Mem 34')),
        findsNothing,
      );
      expect(find.text('Mem 33'), findsNothing);
      expect(find.text('Mem 34'), findsNothing);
      expect(find.text('Mem 20'), findsOneWidget);
    },
  );

  testWidgets(
    'shows same-weekday time, count / total time, total count on the habitual card only',
    (tester) async {
      final overdue = at(20, DateTime(2020, 1, 1, 10));
      final upcoming = at(2, DateTime(2099, 1, 1, 10));
      final habitual = savedMem(
        id: 30,
        name: 'Mem 30',
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final mems = [upcoming, overdue, habitual];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
            memEntitiesProvider.overrideWith(() => _FakeMemEntities(mems)),
            savedMemNotificationsProvider.overrideWith(
              (ref) => ListValueStateNotifier<SavedMemNotificationEntityV1>([]),
            ),
            for (final mem in mems)
              memNotificationsByMemIdProvider(mem.id).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
            overdueMemsProvider.overrideWith(_overdueFromMemEntities),
            habitualMemsProvider.overrideWith(
              (ref) async => [
                habitualMem(
                  overdue,
                  sameWeekdayTime: const Duration(hours: 5),
                  sameWeekdayCount: 6,
                  totalTime: const Duration(hours: 7),
                  totalCount: 8,
                ),
                habitualMem(
                  upcoming,
                  sameWeekdayTime: const Duration(hours: 8),
                  sameWeekdayCount: 9,
                  totalTime: const Duration(hours: 9),
                  totalCount: 10,
                ),
                habitualMem(
                  habitual,
                  sameWeekdayTime: const Duration(hours: 1),
                  sameWeekdayCount: 2,
                  totalTime: const Duration(hours: 3),
                  totalCount: 4,
                ),
              ],
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      List<String> textsIn(Finder card) => tester
          .widgetList<Text>(
            find.descendant(of: card, matching: find.byType(Text)),
          )
          .map((text) => text.data)
          .whereType<String>()
          .toList();

      final habitualCard = find.ancestor(
        of: find.byIcon(Icons.schedule),
        matching: find.byType(Card),
      );
      expect(
        textsIn(habitualCard),
        containsAllInOrder(['Mem 30', '01 h 00 m, 2', ' / ', '03 h 00 m, 4']),
      );

      Finder cardOf(String name) => find.ancestor(
            of: find.text(name),
            matching: find.byType(Card),
          );

      for (final name in ['Mem 20', 'Mem 2']) {
        final texts = textsIn(cardOf(name));
        expect(texts, isNot(contains('01 h 00 m, 2')));
        expect(texts, isNot(contains('03 h 00 m, 4')));
        expect(texts, isNot(contains(' / ')));
      }
      expect(find.text('05 h 00 m, 6'), findsNothing);
      expect(find.text('07 h 00 m, 8'), findsNothing);
      expect(find.text('08 h 00 m, 9'), findsNothing);
      expect(find.text('09 h 00 m, 10'), findsNothing);
    },
  );

  testWidgets(
    'pull to refresh reloads mem names, period counts, and habitual mems',
    (tester) async {
      // px。中身が短くても overscroll して RefreshIndicator が走る
      const reloadFlingDistance = 300.0;
      // px/秒。引き下げとして扱われる速度
      const reloadFlingSpeed = 1000.0;
      // RefreshIndicator が閉じるまで。pumpAndSettle はインジケータが残ると終わらない
      const refreshIndicatorSettle = Duration(seconds: 1);
      // 1日5回。未達なので表示回数は期間回数のまま `n / 5` になる
      const dayTargetCount = 5;
      const periodCountBeforeReload = 1;
      const periodCountAfterReload = 4;
      const countedMemId = 2;
      const oftenMemId = 30;
      const laterMemId = 31;
      const beforeName = 'Before';
      const oftenName = 'Often';
      const laterName = 'Later';

      final counted = savedMem(
        id: countedMemId,
        name: beforeName,
        createdAt: createdAt,
        updatedAt: createdAt,
        notifyOn: DateTime(2099, 1, 1, 10),
        notifyAt: DateTime(2099, 1, 1, 10),
        target: Target(
          memId: countedMemId,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: dayTargetCount,
          period: Period.aDay,
        ),
      );
      final often = savedMem(
        id: oftenMemId,
        name: oftenName,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final later = savedMem(
        id: laterMemId,
        name: laterName,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final mems = [counted, often, later];
      var periodCountBuilds = 0;
      var habitualBuilds = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
            memEntitiesProvider.overrideWith(
              () => _FakeMemEntities(mems, renameOnReload: true),
            ),
            savedMemNotificationsProvider.overrideWith(
              (ref) => ListValueStateNotifier<SavedMemNotificationEntityV1>([]),
            ),
            for (final mem in mems)
              memNotificationsByMemIdProvider(mem.id).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
            listPeriodCountByMemIdProvider.overrideWith((ref) async {
              periodCountBuilds += 1;
              final count = periodCountBuilds == 1
                  ? periodCountBeforeReload
                  : periodCountAfterReload;
              return {countedMemId: count};
            }),
            overdueMemsProvider.overrideWith(_overdueFromMemEntities),
            habitualMemsProvider.overrideWith((ref) async {
              habitualBuilds += 1;
              final mem = habitualBuilds == 1 ? often : later;
              return [habitualMem(mem)];
            }),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(beforeName), findsOneWidget);
      expect(find.text('$periodCountBeforeReload'), findsOneWidget);
      expect(find.text(oftenName), findsOneWidget);
      expect(find.text(laterName), findsNothing);

      await tester.fling(
        find.byType(ListView),
        const Offset(0, reloadFlingDistance),
        reloadFlingSpeed,
      );
      await tester.pump();
      await tester.pump(refreshIndicatorSettle);
      await tester.pump(refreshIndicatorSettle);

      expect(find.text('$beforeName$_reloadedNameSuffix'), findsOneWidget);
      expect(find.text('$periodCountAfterReload'), findsOneWidget);
      expect(find.text('$periodCountBeforeReload'), findsNothing);

      final habitualCard = find.ancestor(
        of: find.byIcon(Icons.schedule),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(
          of: habitualCard,
          matching: find.text('$laterName$_reloadedNameSuffix'),
        ),
        findsOneWidget,
      );
      expect(find.text(oftenName), findsNothing);
      expect(find.text('$oftenName$_reloadedNameSuffix'), findsNothing);
    },
  );
}
