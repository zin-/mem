import 'package:flutter/material.dart';
import '../../../entity_factories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/list/item/view.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/list/widget.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_view.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/framework/view/value_state_notifier.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _state;

  _FakeMemEntities(this._state);

  @override
  Iterable<MemEntity> build() => _state;
}

class _ActThenFinishedMemEntities extends MemEntities {
  var _loadCount = 0;

  @override
  Iterable<MemEntity> build() => [];

  @override
  Future<void> loadMemList({bool? archived, bool? done}) async {
    _loadCount += 1;
    final next = _loadCount == 1
        ? _savedMemWithActiveAct(1, 'Running')
        : _savedMemWithFinishedAct(1, 'Running');
    // loadMemListProvider の build 中に state を更新すると Riverpod が拒否する
    await Future<void>.value();
    state = [next];
  }
}

class _FakeActEntities extends ActEntities {
  @override
  Iterable<SavedActEntityV1> build() => [];

  @override
  Future<void> startActby(int memId) async {}

  @override
  Future<void> resumeActBy(int memId) async {}
}

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 9, minute: 0);
}

MemEntity _savedMem(int id, String name) => savedMem(
      id: id,
      name: name,
      createdAt: DateTime(2024, 1, id),
      updatedAt: DateTime(2024, 1, id),
    );

SavedMemNotificationEntityV1 _savedRepeatAtHour(int id, int memId, int hour) {
  final now = DateTime(2024, 6, 1, 12, 0);
  return savedMemNotification(
      id: id,
      memId: memId,
      type: MemNotificationType.repeat,
      timeOfDaySeconds: hour * 60 * 60,
      message: 'Repeat',
      createdAt: now,
      updatedAt: now);
}

MemNotificationEntityV1 _unsavedRepeatAtHour(int memId, int hour) =>
    MemNotificationEntityV1(
      MemNotification.by(
        memId,
        MemNotificationType.repeat,
        hour * 60 * 60,
        'Repeat',
      ),
    );

MemEntity _savedMemWithActiveAct(int id, String name) => savedMem(
      id: id,
      name: name,
      createdAt: DateTime(2024, 1, id),
      updatedAt: DateTime(2024, 1, id),
      latestAct: ActiveAct(id, DateAndTime(2024, 1, 1)),
    );

MemEntity _savedMemWithFinishedAct(int id, String name) => savedMem(
      id: id,
      name: name,
      createdAt: DateTime(2024, 1, id),
      updatedAt: DateTime(2024, 1, id),
      latestAct: FinishedAct(
        id,
        DateAndTime(2024, 1, 1),
        DateAndTime(2024, 1, 1, 1),
      ),
    );

void main() {
  group('MemListWidget', () {
    group('View', () {
      testWidgets('renders top sliver MemListItemView when mem has active act',
          (tester) async {
        final saved = _savedMemWithActiveAct(1, 'Running');
        final entity = saved;
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferenceProvider(startOfDayKey).overrideWith(
                () => _FakePreference(),
              ),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([saved]),
              ),
              memListProvider.overrideWith(
                (ref) => ValueStateNotifier<List<MemEntity>>([entity]),
              ),
              memNotificationsProvider.overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
              memNotificationsByMemIdProvider(1).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
              actEntitiesProvider.overrideWith(() => _FakeActEntities()),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListWidget(scrollController),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MemListItemView), findsOneWidget);
        expect(find.text('Running'), findsOneWidget);
      });

      testWidgets(
          'sticky header uses previous day when repeat time is before start-of-day',
          (tester) async {
        final saved = _savedMem(1, 'Repeat before 9');
        final entity = saved;
        final notification = _savedRepeatAtHour(301, 1, 8);
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferenceProvider(startOfDayKey).overrideWith(
                () => _FakePreference(),
              ),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([saved]),
              ),
              memListProvider.overrideWith(
                (ref) => ValueStateNotifier<List<MemEntity>>([entity]),
              ),
              memNotificationsProvider.overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([
                  notification,
                ]),
              ),
              memNotificationsByMemIdProvider(1).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([
                  notification,
                ]),
              ),
              actEntitiesProvider.overrideWith(() => _FakeActEntities()),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListWidget(scrollController),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DateAndTimeText), findsOneWidget);
        expect(find.byType(MemListItemView), findsOneWidget);
      });

      testWidgets(
          'sticky header shows ToDo when only unsaved notifications exist',
          (tester) async {
        final saved = _savedMem(1, 'Unsaved notification only');
        final entity = saved;
        final unsavedNotification = _unsavedRepeatAtHour(1, 8);
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferenceProvider(startOfDayKey).overrideWith(
                () => _FakePreference(),
              ),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([saved]),
              ),
              memListProvider.overrideWith(
                (ref) => ValueStateNotifier<List<MemEntity>>([entity]),
              ),
              memNotificationsProvider.overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([
                  unsavedNotification,
                ]),
              ),
              savedMemNotificationsProvider.overrideWith(
                (ref) =>
                    ListValueStateNotifier<SavedMemNotificationEntityV1>([]),
              ),
              memNotificationsByMemIdProvider(1).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([
                  unsavedNotification,
                ]),
              ),
              actEntitiesProvider.overrideWith(() => _FakeActEntities()),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListWidget(scrollController),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(buildL10n().memListToDoSubHeader),
          findsOneWidget,
        );
        expect(find.byType(DateAndTimeText), findsNothing);
        expect(find.byType(MemListItemView), findsOneWidget);
      });

      testWidgets(
          'sticky header shows ToDo subheader when next notify time is absent',
          (tester) async {
        final saved = _savedMem(1, 'No schedule');
        final entity = saved;
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferenceProvider(startOfDayKey).overrideWith(
                () => _FakePreference(),
              ),
              memEntitiesProvider.overrideWith(
                () => _FakeMemEntities([saved]),
              ),
              memListProvider.overrideWith(
                (ref) => ValueStateNotifier<List<MemEntity>>([entity]),
              ),
              memNotificationsProvider.overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
              memNotificationsByMemIdProvider(1).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
              ),
              actEntitiesProvider.overrideWith(() => _FakeActEntities()),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListWidget(scrollController),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(buildL10n().memListToDoSubHeader),
          findsOneWidget,
        );
        expect(find.byType(MemListItemView), findsOneWidget);
      });

      testWidgets(
          'pull to refresh shows play after an active mem becomes finished',
          (tester) async {
        final notification = _savedRepeatAtHour(301, 1, 9);
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferenceProvider(startOfDayKey).overrideWith(
                () => _FakePreference(),
              ),
              memEntitiesProvider.overrideWith(
                () => _ActThenFinishedMemEntities(),
              ),
              memNotificationsProvider.overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([
                  notification,
                ]),
              ),
              memNotificationsByMemIdProvider(1).overrideWith(
                (ref) => ListValueStateNotifier<MemNotificationEntityV1>([
                  notification,
                ]),
              ),
              actEntitiesProvider.overrideWith(() => _FakeActEntities()),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MemListWidget(scrollController),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsNothing);

        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsNothing);
      });
    });
  });
}
