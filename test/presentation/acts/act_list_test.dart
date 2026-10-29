import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/list/act_list.dart';
import 'package:mem/features/acts/list/item/total_act_time_item.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import '../../entity_factories.dart';

const _memId = 2;
const _memName = 'mem-a';

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _initial;

  _FakeMemEntities(this._initial);

  @override
  Iterable<MemEntity> build() => _initial;
}

DateTime _anotherDayThisMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day == 1 ? 2 : 1, 10);
}

void main() {
  testWidgets(
    'hides actions for another day this month in date and time view',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final day = _anotherDayThisMonth();
      final act = savedAct(
        id: 1,
        memId: _memId,
        start: day,
        end: day.add(const Duration(hours: 1)),
        createdAt: day,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            memEntitiesProvider.overrideWith(
              () => _FakeMemEntities([
                savedMem(id: _memId, name: _memName),
              ]),
            ),
            actListProvider(_memId).overrideWith((ref) => [act]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ActList(_memId, null),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
}
