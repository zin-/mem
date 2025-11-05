import 'package:collection/collection.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_client.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/mem_store.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/shared/entities_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mems_state.g.dart';

@Riverpod(keepAlive: true)
class MemEntities extends _$MemEntities
    with EntitiesStateMixin<SavedMemEntity, int> {
  @override
  Iterable<SavedMemEntity> build() => v(
        () {
          ref.listen<bool>(showNotArchivedProvider, (_, __) => loadMemList());
          ref.listen<bool>(showArchivedProvider, (_, __) => loadMemList());
          ref.listen<bool>(showNotDoneProvider, (_, __) => loadMemList());
          ref.listen<bool>(showDoneProvider, (_, __) => loadMemList());

          loadMemList();

          return [];
        },
      );

  Future<void> loadMemList() => v(
        () async {
          final showNotArchived = ref.read(showNotArchivedProvider);
          final showArchived = ref.read(showArchivedProvider);
          final showNotDone = ref.read(showNotDoneProvider);
          final showDone = ref.read(showDoneProvider);

          final mems = await MemStore().serve(
            archived: showNotArchived == showArchived ? null : showArchived,
            done: showNotDone == showDone ? null : showDone,
          );

          upsert(mems);
        },
      );

  Future<SavedMemEntity?> loadByMemId(int memId) => v(
        () async {
          final mem = await MemRepository().ship(id: memId);

          upsert(mem);

          return mem.singleOrNull;
        },
        {'memId': memId},
      );

  Future<
      (
        (
          MemEntity,
          List<MemItemEntity>,
          List<MemNotificationEntity>?,
          TargetEntity?,
          List<MemRelationEntity>?
        ),
        DateTime?
      )> save(
    MemEntity memEntity,
    Iterable<MemItemEntity> memItemEntities,
    Iterable<MemNotificationEntity> memNotificationEntities,
    TargetEntity? targetEntity,
    Iterable<MemRelationEntity>? memRelationEntities,
  ) =>
      v(
        () async {
          final (saved, nextNotifyAt) = await MemClient().save(
            memEntity,
            memItemEntities.toList(),
            memNotificationEntities.toList(),
            targetEntity,
            memRelationEntities?.toList(),
          );

          upsert([saved.$1 as SavedMemEntity]);

          ref
              .read(memRelationEntitiesProvider.notifier)
              .upsert(saved.$5?.whereType<SavedMemRelationEntity>() ?? []);

          return (saved, nextNotifyAt);
        },
        {
          'memEntity': memEntity,
          'memItemEntities': memItemEntities,
          'memNotificationEntities': memNotificationEntities,
          'targetEntity': targetEntity,
          'memRelationEntities': memRelationEntities,
        },
      );

  Future<Iterable<SavedMemEntity>> removeAsync(Iterable<int> ids) => v(
        () async {
          await Future.wait(ids.map((id) => MemClient().remove(id)));

          return remove(ids);
        },
        {'ids': ids},
      );

  Future<
      (
        MemEntity,
        List<MemItemEntity>,
        List<MemNotificationEntity>?,
        TargetEntity?,
        List<MemRelationEntity>?
      )?> undoRemove(int id) => v(
        () async {
          // ignore: avoid_manual_providers_as_generated_provider_dependency
          final removedMemDetail = ref.read(removedMemDetailProvider(id));

          if (removedMemDetail != null) {
            // FIXME serviceを利用しているが、clientを利用するべきでは？
            // FIXME ここでserviceの初期化をしているが、stateをbuildしたタイミングでseviceの初期化もしたい
            //   repositoryの親子関係解決を確定するタイミングの問題で、現時点ではここで初期化する必要がある
            //   https://github.com/zin-/mem/issues/472
            final undoneRemovedMemDetail =
                await MemService().save(removedMemDetail, undo: true);

            upsert([undoneRemovedMemDetail.$1 as SavedMemEntity]);

            return undoneRemovedMemDetail;
          }

          return null;
        },
        {'id': id},
      );

  void doneMem(int memId) => v(
        () async {
          final doneMemDetail = await MemService().doneByMemId(memId);

          upsert([doneMemDetail.$1 as SavedMemEntity]);
        },
        {'memId': memId},
      );

  void undoneMem(int memId) => v(
        () async {
          final undoneMemDetail = await MemService().undoneByMemId(memId);

          upsert([undoneMemDetail.$1 as SavedMemEntity]);
        },
        {'memId': memId},
      );

  void archive(int? memId) => v(
        () async {
          final targetMem = state.singleWhereOrNull((e) => e.id == memId);

          if (targetMem == null) {
            return;
          }

          final archived = await MemClient().archive(targetMem);

          upsert([archived.$1 as SavedMemEntity]);
        },
        {'memId': memId},
      );

  void unarchive(int? memId) => v(
        () async {
          final targetMem = state.singleWhereOrNull((e) => e.id == memId);

          if (targetMem == null) {
            return;
          }

          final unarchived = await MemClient().unarchive(targetMem);

          upsert([unarchived.$1 as SavedMemEntity]);
        },
      );
}
