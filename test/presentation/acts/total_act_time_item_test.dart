import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/list/item/total_act_time_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/mems/detail/page.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_name.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/generated/l10n/app_localizations.dart';

import '../../entity_factories.dart';

const _memId = 2;
const _memName = 'mem-a';

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _initial;

  _FakeMemEntities(this._initial);

  @override
  Iterable<MemEntity> build() => _initial;
}

class _FakeTargetState extends TargetState {
  @override
  Future<TargetEntityV1> build(int? memId) async => TargetEntityV1(
        Target(
          memId: memId,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: 1,
          period: Period.aDay,
        ),
      );
}

class _FakeMemRelationEntitiesByMemId extends MemRelationEntitiesByMemId {
  @override
  Future<Iterable<MemRelationEntityV1>> build(int? memId) async => [];
}

class _FakePreference extends Preference<TimeOfDay> {
  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 0, minute: 0);
}

void main() {
  final mem = Mem(_memId, _memName, null, null);

  List<Override> overrides() => [
        memEntitiesProvider.overrideWith(
          () => _FakeMemEntities([
            savedMem(id: _memId, name: _memName),
          ]),
        ),
        memNotificationsByMemIdProvider(_memId).overrideWith(
          (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
        ),
        memItemsByMemIdProvider(_memId).overrideWith(
          (ref) => ListValueStateNotifier<MemItemEntityV1>([]),
        ),
        targetStateProvider(_memId).overrideWith(() => _FakeTargetState()),
        memRelationEntitiesByMemIdProvider(_memId).overrideWith(
          () => _FakeMemRelationEntitiesByMemId(),
        ),
        preferenceProvider(startOfDayKey).overrideWith(() => _FakePreference()),
      ];

  Future<void> pumpItem(WidgetTester tester, Mem? mem) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TotalActTimeListItem(
              [
                savedAct(
                  id: 1,
                  memId: _memId,
                  start: DateTime(2024, 6, 1, 10),
                  end: DateTime(2024, 6, 1, 11),
                  createdAt: DateTime(2024, 6, 1),
                ),
              ],
              mem,
              null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('TotalActTimeListItem', () {
    testWidgets('opens mem detail on tap and has no arrow', (tester) async {
      await pumpItem(tester, mem);

      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.text(_memName), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(MemDetailPage), findsOneWidget);
      expect(find.byKey(keyMemName), findsOneWidget);
      expect(find.text(_memName), findsOneWidget);
    });

    testWidgets('opens mem detail from act mem id when mem is omitted',
        (tester) async {
      await pumpItem(tester, null);

      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.text(_memName), findsNothing);

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(MemDetailPage), findsOneWidget);
      expect(find.text(_memName), findsOneWidget);
    });
  });
}
