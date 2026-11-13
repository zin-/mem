import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/home/habitual_mems.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/home_screen.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/values/colors.dart';

import '../../../entity_factories.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _state;
  int loadCount = 0;

  _FakeMemEntities(this._state);

  @override
  Iterable<MemEntity> build() => _state;

  @override
  Future<void> loadMemList({bool? archived, bool? done}) async {
    loadCount += 1;
  }
}

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 9, minute: 0);
}

void main() {
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
      final memEntities = _FakeMemEntities(mems);
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
            habitualMemsProvider.overrideWith((ref) async => <HabitualMem>[]),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(memEntities.loadCount, greaterThan(0));
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
        containsAllInOrder(['Mem 30', '1:00, 2', ' / ', '3:00, 4']),
      );

      Finder cardOf(String name) => find.ancestor(
            of: find.text(name),
            matching: find.byType(Card),
          );

      for (final name in ['Mem 20', 'Mem 2']) {
        final texts = textsIn(cardOf(name));
        expect(texts, isNot(contains('1:00, 2')));
        expect(texts, isNot(contains('3:00, 4')));
        expect(texts, isNot(contains(' / ')));
      }
      expect(find.text('5:00, 6'), findsNothing);
      expect(find.text('7:00, 8'), findsNothing);
      expect(find.text('8:00, 9'), findsNothing);
      expect(find.text('9:00, 10'), findsNothing);
    },
  );
}
