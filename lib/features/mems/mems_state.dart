import 'package:collection/collection.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/mem_client.dart';
import 'package:mem/features/mems/mem_detail.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/shared/entities_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mems_state.g.dart';

@riverpod
class MemEntities extends _$MemEntities
    with EntitiesStateMixin<SavedMemEntityV2, int> {
  @override
  Iterable<SavedMemEntityV2> build() {
    return [];
  }

  Future<List<SavedMemEntityV2>> loadMemList(
    bool showArchived,
    bool showNotArchived,
    bool showDone,
    bool showNotDone,
  ) =>
      v(
        () async {
          final mems = await MemRepositoryV2().ship(
            archived: showNotArchived == showArchived ? null : showArchived,
            done: showNotDone == showDone ? null : showDone,
          );

          upsert(mems);

          return mems;
        },
        {
          'showArchived': showArchived,
          'showNotArchived': showNotArchived,
          'showDone': showDone,
          'showNotDone': showNotDone,
        },
      );

  Future<SavedMemEntityV2?> loadByMemId(int memId) => v(
        () async {
          final mem = await MemRepositoryV2().ship(id: memId);

          upsert(mem);

          return mem.singleOrNull;
        },
        {'memId': memId},
      );

  Future<MemDetail> save(
    MemEntityV2 memEntity,
    Iterable<MemItemEntityV2> memItemEntities,
    Iterable<MemNotificationEntityV2> memNotificationEntities,
    TargetEntity? targetEntity,
  ) =>
      v(
        () async {
          final saved = await MemClient().save(
            memEntity,
            memItemEntities.toList(),
            memNotificationEntities.toList(),
            targetEntity,
          );

          upsert([saved.mem as SavedMemEntityV2]);

          return saved;
        },
        {
          'memEntity': memEntity,
          'memItemEntities': memItemEntities,
          'memNotificationEntities': memNotificationEntities,
          'targetEntity': targetEntity,
        },
      );

  @override
  Iterable<SavedMemEntityV2> remove(Iterable<int> ids) => v(
        () {
          ids.map((id) => MemClient().remove(id));

          return super.remove(ids);
        },
        {'ids': ids},
      );

  Future<MemDetail?> undoRemove(int id) => v(
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

            upsert([undoneRemovedMemDetail.mem as SavedMemEntityV2]);

            return undoneRemovedMemDetail;
          }

          return null;
        },
        {'id': id},
      );

  void doneMem(int memId) => v(
        () async {
          final doneMemDetail = await MemService().doneByMemId(memId);

          upsert([doneMemDetail.mem as SavedMemEntityV2]);
        },
        {'memId': memId},
      );

  void undoneMem(int memId) => v(
        () async {
          final undoneMemDetail = await MemService().undoneByMemId(memId);

          upsert([undoneMemDetail.mem as SavedMemEntityV2]);
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

          upsert([archived.mem as SavedMemEntityV2]);
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

          upsert([unarchived.mem as SavedMemEntityV2]);
        },
      );
}
