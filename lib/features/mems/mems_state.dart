import 'package:collection/collection.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
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
    with EntitiesStateMixinV1<SavedMemEntityV1, int> {
  @override
  Iterable<SavedMemEntityV1> build() => v(
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

  Future<SavedMemEntityV1> loadByMemId(int memId) => v(
        () async {
          final mem = await MemRepository()
              .shipById(memId)
              .then((v) => SavedMemEntityV1.fromEntityV2(v));

          upsert([mem]);

          return mem;
        },
        {'memId': memId},
      );

  Future<Iterable<SavedMemEntityV1>> removeAsync(Iterable<int> ids) => v(
        () async {
          await Future.wait(ids.map((id) => MemClient().remove(id)));

          return remove(ids);
        },
        {'ids': ids},
      );

  Future<void> undoRemove(int id) => v(
        () async {
          // ignore: avoid_manual_providers_as_generated_provider_dependency
          final removedMemDetail = ref.read(removedMemDetailProvider(id));

          if (removedMemDetail != null) {
            // FIXME serviceを利用しているが、clientを利用するべきでは？
            // FIXME ここでserviceの初期化をしているが、stateをbuildしたタイミングでseviceの初期化もしたい
            //   repositoryの親子関係解決を確定するタイミングの問題で、現時点ではここで初期化する必要がある
            //   https://github.com/zin-/mem/issues/472
            final (
              undoneRemovedMemEntityV1,
              undoneRemovedMemItems,
              undoneRemovedMemNotifications,
              undoneRemovedTarget,
              undoneRemovedMemRelations,
              undoneRemovedMemEntityV2
            ) = await MemService().save(removedMemDetail, undo: true);

            upsert([undoneRemovedMemEntityV1]);
            ref.read(memItemsProvider.notifier).upsertAll(
                  undoneRemovedMemItems,
                  (current, updating) =>
                      current is SavedMemItemEntityV1 &&
                      updating is SavedMemItemEntityV1 &&
                      current.id == updating.id,
                );
          }
        },
        {'id': id},
      );

  void doneMem(int memId) => v(
        () async {
          final doneMem = await MemService().doneByMemId(memId);

          upsert([doneMem]);
        },
        {'memId': memId},
      );

  void undoneMem(int memId) => v(
        () async {
          final undoneMem = await MemService().undoneByMemId(memId);

          upsert([undoneMem]);
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

          upsert([SavedMemEntityV1.fromEntityV2(archived)]);
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

          upsert([SavedMemEntityV1.fromEntityV2(unarchived)]);
        },
      );
}
