import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/list/widget.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
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
  int startActbyCallCount = 0;
  int? lastStartActbyMemId;

  @override
  Iterable<SavedActEntityV1> build() => [];

  @override
  Future<void> startActby(int memId) async {
    startActbyCallCount++;
    lastStartActbyMemId = memId;
  }
}

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 9, minute: 0);
}

SavedMemEntityV1 _savedMem(int id, String name) => SavedMemEntityV1(
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
    );

SavedMemNotificationEntityV1 _savedNotification(int id, int memId) {
  final now = DateTime(2024, 6, 1, 12, 0);
  return SavedMemNotificationEntityV1({
    defPkId.name: id,
    defFkMemNotificationsMemId.name: memId,
    defColMemNotificationsType.name: 'repeat',
    defColMemNotificationsTime.name: 9 * 60 * 60,
    defColMemNotificationsMessage.name: 'Repeat',
    defColCreatedAt.name: now,
    defColUpdatedAt.name: now,
    defColArchivedAt.name: null,
  });
}

void main() {
  group('MemListWidget', () {
    group('Actions', () {
      testWidgets(
        'after reordering list, play on first row starts act for that row mem',
        (tester) async {
          final saved1 = _savedMem(1, 'First');
          final saved2 = _savedMem(2, 'Second');
          final entity1 = saved1.toEntityV2();
          final entity2 = saved2.toEntityV2();
          final notification1 = _savedNotification(101, 1);
          final notification2 = _savedNotification(102, 2);
          final fakeAct = _FakeActEntities();
          final scrollController = ScrollController();

          addTearDown(scrollController.dispose);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                preferenceProvider(startOfDayKey).overrideWith(
                  () => _FakePreference(),
                ),
                memEntitiesProvider.overrideWith(
                  () => _FakeMemEntities([saved1, saved2]),
                ),
                memListProvider.overrideWith(
                  (ref) => ValueStateNotifier<List<MemEntity>>([
                    entity1,
                    entity2,
                  ]),
                ),
                memNotificationsProvider.overrideWith(
                  (ref) => ListValueStateNotifier<MemNotificationEntityV1>([
                    notification1,
                    notification2,
                  ]),
                ),
                memNotificationsByMemIdProvider(1).overrideWith(
                  (ref) => ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification1],
                  ),
                ),
                memNotificationsByMemIdProvider(2).overrideWith(
                  (ref) => ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification2],
                  ),
                ),
                memStateProvider(1)
                    .overrideWith(() => _FakeMemState(saved1.value)),
                memStateProvider(2)
                    .overrideWith(() => _FakeMemState(saved2.value)),
                latestActsByMemProvider.overrideWith(
                  (ref) => {1: null, 2: null},
                ),
                actEntitiesProvider.overrideWith(() => fakeAct),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: MemListWidget(scrollController),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final container = ProviderScope.containerOf(
              tester.element(find.byType(MemListWidget)));
          container.read(memListProvider.notifier).state = [entity2, entity1];
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.play_arrow).first);
          await tester.pump();

          expect(fakeAct.startActbyCallCount, 1);
          expect(fakeAct.lastStartActbyMemId, 2);
        },
      );
    });
  });
}
