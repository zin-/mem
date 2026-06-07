import '../../../entity_factories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<SavedMemEntityV1> _initial;

  _FakeMemEntities(this._initial);

  @override
  Iterable<SavedMemEntityV1> build() => _initial;
}

void main() {
  group('editingMemByMemIdProvider', () {
    test('keeps edited period when memByMemIdProvider updates', () {
      const memId = 1;
      final mem = savedMem(
        id: memId,
        name: 'Test mem',
        notifyOn: DateTime(2024, 6, 1),
        endOn: DateTime(2024, 6, 2),
      );

      final container = ProviderContainer(
        overrides: [
          memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem])),
        ],
      );
      addTearDown(container.dispose);

      final editingNotifier =
          container.read(editingMemByMemIdProvider(memId).notifier);
      final editingMem = container.read(editingMemByMemIdProvider(memId));

      final editedPeriod = DateAndTimePeriod(
        start: DateAndTime(2024, 6, 1, 14, 0),
        end: DateAndTime(2024, 6, 2),
      );

      editingNotifier.updatedBy(
        editingMem.updatedWith(
          (m) => Mem(m.id, m.name, m.doneAt, editedPeriod),
        ),
      );

      final refreshedMem = savedMem(
        id: memId,
        name: 'Test mem',
        notifyOn: DateTime(2024, 6, 1),
        endOn: DateTime(2024, 6, 2),
        latestAct: PausedAct(memId, DateTime(2024, 6, 1, 12, 0)),
      );
      container.read(memEntitiesProvider.notifier).upsert([refreshedMem]);

      final afterUpdate = container.read(editingMemByMemIdProvider(memId));

      expect(afterUpdate.value.period?.start?.hour, 14);
      expect(afterUpdate.value.period?.start?.minute, 0);
    });
  });
}
