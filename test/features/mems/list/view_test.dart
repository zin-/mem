import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/list/item/view.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/list/widget.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/framework/view/value_state_notifier.dart';

class _FakeMemState extends MemState {
  final Mem _mem;

  _FakeMemState(this._mem);

  @override
  Future<Mem> build(int? memId) async {
    return _mem;
  }
}

class _FakeMemEntities extends MemEntities {
  final Iterable<SavedMemEntityV1> _state;

  _FakeMemEntities(this._state);

  @override
  Iterable<SavedMemEntityV1> build() => _state;
}

class _FakeActEntities extends ActEntities {
  @override
  Iterable<SavedActEntityV1> build() => [];

  @override
  Future<void> startActby(int memId) async {}
}

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 9, minute: 0);
}

SavedMemEntityV1 _savedMemWithActiveAct(int id, String name) =>
    SavedMemEntityV1(
      {
        defPkId.name: id,
        defColMemsName.name: name,
        defColMemsDoneAt.name: null,
        'notifyOn': null,
        'notifyAt': null,
        'endOn': null,
        'endAt': null,
        defColCreatedAt.name: DateTime(2024, 1, id),
        defColUpdatedAt.name: DateTime(2024, 1, id),
        defColArchivedAt.name: null,
      },
      latestAct: ActiveAct(id, DateAndTime(2024, 1, 1)),
    );

void main() {
  group('MemListWidget', () {
    group('View', () {
      testWidgets(
          'renders top sliver MemListItemView when mem has active act',
          (tester) async {
        final saved = _savedMemWithActiveAct(1, 'Running');
        final entity = saved.toEntityV2();
        final activeAct = ActiveAct(1, DateAndTime(2024, 1, 1));
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
              memStateProvider(1)
                  .overrideWith(() => _FakeMemState(saved.value)),
              latestActsByMemProvider.overrideWith(
                (ref) => {1: activeAct},
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
    });
  });
}
