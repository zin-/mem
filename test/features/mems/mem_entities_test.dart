import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/databases/database.dart' hide Mem, MemParent;
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mem_parents/mem_parent.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mems/list/filter_value.dart';
import 'package:mem/features/mems/list/states.dart';
import 'list/helpers.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_client.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MemClient.resetSingleton();
    MemService.resetSingleton();
    Singleton.reset<MemRepository>();
    Singleton.reset<MemNotificationRepository>();
    Singleton.reset<MemRelationRepository>();
    Singleton.reset<TargetRepository>();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(AppDatabase.memory()),
    );
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    MemClient.resetSingleton();
    MemService.resetSingleton();
    await DriftRepository.close();
    Singleton.reset<MemRepository>();
    Singleton.reset<MemNotificationRepository>();
    Singleton.reset<MemRelationRepository>();
    Singleton.reset<TargetRepository>();
  });

  MemEntities notifier() => container.read(memEntitiesProvider.notifier);

  MemEntity cachedMem(int id) => container
      .read(memEntitiesProvider)
      .singleWhere((entity) => entity.id == id);

  Future<MemEntity> insertMem(String name) =>
      MemRepository().receive(Mem(null, name, null, null));

  test(
      'default reload keeps active mems, later reloads grow the cache, and the list follows the filter',
      () async {
    final active = await insertMem('active');
    final archived = await insertMem('archived');
    final done = await insertMem('done');
    await MemRepository().replace(
      archived.updatedWith(archivedAt: () => DateTime(2024, 1, 2)),
    );
    await MemRepository().replace(
      done.updatedWith(update: (mem) => mem.done(DateTime(2024, 1, 3))),
    );

    container.dispose();
    container = ProviderContainer(
      overrides: [
        memEntitiesProvider.overrideWith(() => FakeMemEntities()),
        preferenceProvider(startOfDayKey)
            .overrideWith(() => FakeStartOfDayPreference()),
      ],
    );

    final subscription = container.listen(memListProvider, (_, __) {});
    addTearDown(subscription.close);
    await container.read(loadMemListProvider.future);

    expect(
      container.read(memEntitiesProvider).map((mem) => mem.id).toSet(),
      {active.id},
    );
    expect(sortedMemIds(container), [active.id]);

    container.read(memListFilterStateProvider.notifier).updatedBy(
          const MemListFilterValue(
            showNotArchived: false,
            showArchived: true,
          ),
        );
    await container.read(loadMemListProvider.future);

    expect(
      container.read(memEntitiesProvider).map((mem) => mem.id).toSet(),
      {active.id, archived.id},
    );
    expect(sortedMemIds(container), [archived.id]);

    container.read(memListFilterStateProvider.notifier).updatedBy(
          const MemListFilterValue(
            showNotDone: false,
            showDone: true,
          ),
        );
    await container.read(loadMemListProvider.future);

    expect(
      container.read(memEntitiesProvider).map((mem) => mem.id).toSet(),
      {active.id, archived.id, done.id},
    );
    expect(sortedMemIds(container), [done.id]);
  });

  test('refreshLatestActForMem ignores a missing id and reloads a saved mem',
      () async {
    await notifier().refreshLatestActForMem(-1);
    expect(container.read(memEntitiesProvider), isEmpty);

    final saved = await insertMem('reloaded');
    await notifier().refreshLatestActForMem(saved.id);

    expect(container.read(memEntitiesProvider).single.name, 'reloaded');
  });

  test('removeAsync drops the mem and undoRemove puts it back', () async {
    final saved = await insertMem('gone');
    await notifier().loadMemList();

    container.read(removedMemProvider(saved.id).notifier).updatedBy(
          MemViewData(Mem(saved.id, 'back', null, null)),
        );
    await notifier().undoRemove(saved.id);
    expect(container.read(memEntitiesProvider).single.name, 'back');

    final removed = await notifier().removeAsync([saved.id]);
    expect(removed.map((mem) => mem.id), [saved.id]);
    expect(container.read(memEntitiesProvider), isEmpty);
  });

  test('archive and unarchive update state, and ignore an unknown id',
      () async {
    final saved = await insertMem('live');
    await notifier().loadMemList();

    await notifier().archive(null);
    expect(container.read(memEntitiesProvider).single.archivedAt, isNull);

    await notifier().archive(saved.id);
    expect(container.read(memEntitiesProvider).single.archivedAt, isNotNull);

    await notifier().unarchive(null);
    expect(container.read(memEntitiesProvider).single.archivedAt, isNotNull);

    await notifier().unarchive(saved.id);
    expect(container.read(memEntitiesProvider).single.archivedAt, isNull);
  });

  test('loadDetail caches parent links and does not replace a cached mem',
      () async {
    final parent = await insertMem('Parent');
    final child = await insertMem('Child');
    final other = await insertMem('Other');
    await MemRepository().receiveParent(
      MemParent(memId: child.id, parentMemId: parent.id),
    );
    await MemRepository().receiveParent(
      MemParent(memId: other.id, parentMemId: child.id),
    );
    notifier().upsert([
      parent.updatedWith(
        update: (mem) => Mem(mem.id, 'kept', mem.doneAt, mem.period),
      ),
    ]);

    final first = notifier().loadDetail(child.id);
    final second = notifier().loadDetail(child.id);
    expect(second, same(first));
    await first;

    final loadedChild = cachedMem(child.id);
    expect(loadedChild.parentsLoaded, isTrue);
    expect(loadedChild.parentMemId, parent.id);
    expect(loadedChild.childMemIds, [other.id]);
    expect(cachedMem(parent.id).name, 'kept');
    expect(cachedMem(parent.id).parentsLoaded, isFalse);
    expect(cachedMem(other.id).name, 'Other');
    expect(cachedMem(other.id).parentsLoaded, isFalse);

    await MemRepository().wasteParents(memId: child.id);
    await notifier().loadDetail(child.id);

    expect(cachedMem(child.id).parentsLoaded, isTrue);
    expect(cachedMem(child.id).parentMemId, isNull);
    expect(cachedMem(child.id).childMemIds, [other.id]);
    expect(cachedMem(parent.id).name, 'kept');

    await notifier().loadByMemId(child.id);

    expect(cachedMem(child.id).parentsLoaded, isTrue);
    expect(cachedMem(child.id).parentMemId, isNull);
    expect(cachedMem(child.id).childMemIds, [other.id]);
  });

  test('doneMem and undoneMem update state', () async {
    final saved = await insertMem('open');
    await notifier().loadMemList();

    await notifier().doneMem(saved.id);
    expect(container.read(memEntitiesProvider).single.doneAt, isNotNull);

    await notifier().undoneMem(saved.id);
    expect(container.read(memEntitiesProvider).single.doneAt, isNull);
  });

  test('refreshes parent ids with undone children after list and mem changes',
      () async {
    final parent = await insertMem('parent');
    final child = await insertMem('child');
    await MemRepository().receiveParent(
      MemParent(memId: child.id, parentMemId: parent.id),
    );

    Set<int> parentIds() =>
        container.read(parentMemIdsWithUndoneChildrenProvider);

    expect(parentIds(), isEmpty);

    await notifier().loadMemList();
    expect(parentIds(), {parent.id});

    await notifier().doneMem(child.id);
    expect(parentIds(), isEmpty);

    await notifier().undoneMem(child.id);
    expect(parentIds(), {parent.id});

    await notifier().archive(child.id);
    expect(parentIds(), isEmpty);

    await notifier().unarchive(child.id);
    expect(parentIds(), {parent.id});

    await notifier().removeAsync([child.id]);
    expect(parentIds(), isEmpty);
  });
}
