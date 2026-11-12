import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/detail/states.dart';
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
}
