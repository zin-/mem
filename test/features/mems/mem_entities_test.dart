import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/databases/database.dart' hide Mem;
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mems/list/states.dart';
import 'list/helpers.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_client.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/mem_store.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
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
    MemStore.resetSingleton();
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
    MemStore.resetSingleton();
    await DriftRepository.close();
    Singleton.reset<MemRepository>();
    Singleton.reset<MemNotificationRepository>();
    Singleton.reset<MemRelationRepository>();
    Singleton.reset<TargetRepository>();
  });

  MemEntities notifier() => container.read(memEntitiesProvider.notifier);

  Future<MemEntity> insertMem(String name) =>
      MemRepository().receive(Mem(null, name, null, null));

  test('build reloads when archive and done filters change', () async {
    await insertMem('active');
    container.read(memEntitiesProvider);

    container.read(showNotArchivedProvider.notifier).updatedBy(false);
    container.read(showArchivedProvider.notifier).updatedBy(true);
    container.read(showNotDoneProvider.notifier).updatedBy(false);
    container.read(showDoneProvider.notifier).updatedBy(true);
    await notifier().loadMemList();
  });

  test('loadMemList follows archive and done filters', () async {
    await insertMem('active');
    container.dispose();
    container = ProviderContainer(
      overrides: [
        memEntitiesProvider.overrideWith(() => FakeMemEntities()),
      ],
    );

    await notifier().loadMemList();
    expect(container.read(memEntitiesProvider), hasLength(1));

    container.read(showArchivedProvider.notifier).updatedBy(true);
    container.read(showNotArchivedProvider.notifier).updatedBy(false);
    await notifier().loadMemList();

    container.read(showNotArchivedProvider.notifier).updatedBy(true);
    await notifier().loadMemList();
    expect(container.read(memEntitiesProvider), hasLength(1));

    container.read(showNotDoneProvider.notifier).updatedBy(false);
    container.read(showDoneProvider.notifier).updatedBy(true);
    await notifier().loadMemList();

    container.read(showNotDoneProvider.notifier).updatedBy(true);
    await notifier().loadMemList();
    expect(container.read(memEntitiesProvider), hasLength(1));
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

  test('doneMem and undoneMem update state', () async {
    final saved = await insertMem('open');
    await notifier().loadMemList();

    await notifier().doneMem(saved.id);
    expect(container.read(memEntitiesProvider).single.doneAt, isNotNull);

    await notifier().undoneMem(saved.id);
    expect(container.read(memEntitiesProvider).single.doneAt, isNull);
  });
}
