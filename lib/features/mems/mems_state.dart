import 'package:collection/collection.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mems/mem_client.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/shared/entities_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mems_state.g.dart';

@Riverpod(keepAlive: true)
class MemEntities extends _$MemEntities
    with EntitiesStateMixinV1<MemEntity, int> {
  final _detailLoads = <int, Future<void>>{};

  @override
  Iterable<MemEntity> build() => v(() => []);

  @override
  Iterable<MemEntity> upsert(Iterable<MemEntity> entities) => super.upsert([
        for (final entity in entities) _keepingLoadedParents(entity),
      ]);

  Future<void> loadMemList({bool? archived, bool? done}) => v(
        () async {
          final mems = await MemRepository().ship(
            archived: archived,
            done: done,
            loadLatestAct: true,
          );

          upsert(mems);

          await upsertSavedMemNotifications(
            ref,
            memIdsIn: mems.map((e) => e.id),
          );
          await _refreshParentMemIdsWithUndoneChildren();
        },
        {
          'archived': archived,
          'done': done,
        },
      );

  Future<MemEntity?> loadByMemId(int memId) => v(
        () async {
          final mem = await _shipOne(
            MemRepository(),
            memId,
            loadLatestAct: true,
          );
          if (mem == null) return null;

          upsert([mem]);

          return _entity(mem.id) ?? mem;
        },
        {'memId': memId},
      );

  Future<void> loadDetail(int memId) => v(
        () {
          final inFlight = _detailLoads[memId];
          if (inFlight != null) return inFlight;

          late final Future<void> future;
          future = _fetchDetail(memId).whenComplete(() {
            if (identical(_detailLoads[memId], future)) {
              _detailLoads.remove(memId);
            }
          });
          _detailLoads[memId] = future;
          return future;
        },
        {'memId': memId},
      );

  Future<void> refreshLatestActForMem(int memId) => v(
        () async {
          final mem = await _shipOne(
            MemRepository(),
            memId,
            loadLatestAct: true,
          );
          if (mem == null) return;
          upsert([mem]);
        },
        {'memId': memId},
      );

  Future<void> removeMem(int memId, List<MemItemEntityV1> items) => v(
        () async {
          await MemClient().remove(memId);

          final removed = remove([memId]);
          await _refreshParentMemIdsWithUndoneChildren();
          for (final entity in removed) {
            ref
                .read(removedMemProvider(entity.id).notifier)
                .updatedBy(MemViewData.fromEntity(entity));
            ref
                .read(removedMemItemsProvider(entity.id).notifier)
                .updatedBy(items);
          }
        },
        {'memId': memId},
      );

  Future<void> undoRemove(int id) => v(
        () async {
          // ignore: avoid_manual_providers_as_generated_provider_dependency
          final removedMemDetail = ref.read(removedMemDetailProvider(id));

          if (removedMemDetail != null) {
            final (
              (
                _,
                undoneRemovedMemNotifications,
                undoneRemovedTarget,
                undoneRemovedMemRelations,
                undoneRemovedMemEntity,
              ),
              undoneRemovedMemEntityV2,
            ) = await MemClient().save(
              removedMemDetail.$1,
              removedMemDetail.$2,
              removedMemDetail.$3!,
              removedMemDetail.$4,
              removedMemDetail.$5,
              // undo: true,
            );

            upsert([undoneRemovedMemEntity]);
          }
        },
        {'id': id},
      );

  Future<void> doneMem(int memId) => v(
        () async {
          final doneMem = await MemService().doneByMemId(memId);

          upsert([doneMem]);
          await _refreshParentMemIdsWithUndoneChildren();
        },
        {'memId': memId},
      );

  Future<void> undoneMem(int memId) => v(
        () async {
          final undoneMem = await MemService().undoneByMemId(memId);

          upsert([undoneMem]);
          await _refreshParentMemIdsWithUndoneChildren();
        },
        {'memId': memId},
      );

  Future<void> archive(int? memId) => v(
        () async {
          final targetMem = state.singleWhereOrNull((e) => e.id == memId);

          if (targetMem == null) {
            return;
          }

          final archived = await MemClient().archive(targetMem);

          upsert([archived]);
          await _refreshParentMemIdsWithUndoneChildren();
        },
        {'memId': memId},
      );

  Future<void> unarchive(int? memId) => v(
        () async {
          final targetMem = state.singleWhereOrNull((e) => e.id == memId);

          if (targetMem == null) {
            return;
          }

          final unarchived = await MemClient().unarchive(targetMem);

          upsert([unarchived]);
          await _refreshParentMemIdsWithUndoneChildren();
        },
      );

  Future<MemEntity?> _shipOne(
    MemRepository repository,
    int memId, {
    bool loadLatestAct = false,
  }) async {
    final rows = await repository.ship(
      id: memId,
      loadLatestAct: loadLatestAct,
    );
    if (rows.isEmpty) return null;
    return rows.single;
  }

  Future<void> _fetchDetail(int memId) async {
    final repository = MemRepository();
    final mem = await _shipOne(
      repository,
      memId,
      loadLatestAct: true,
    );
    if (mem == null) {
      final cached = _entity(memId);
      if (cached != null && !cached.parentsLoaded) {
        upsert([cached.updatedWith(parentsLoaded: () => true)]);
      }
      return;
    }
    final parent = await repository.shipParentByMemId(memId);
    final children = await repository.shipChildrenByParentMemId(memId);

    final relatedIds = <int>{
      if (parent != null) parent.parentMemId,
      for (final child in children) child.memId,
    };
    final missing = <MemEntity>[];
    for (final id in relatedIds) {
      if (id == memId || _entity(id) != null) continue;
      final related = await _shipOne(repository, id);
      if (related == null) continue;
      missing.add(related);
    }
    final toInsert = [
      for (final entity in missing)
        if (_entity(entity.id) == null) entity,
    ];
    if (toInsert.isNotEmpty) {
      upsert(toInsert);
    }

    upsert([
      mem.updatedWith(
        parentsLoaded: () => true,
        parentMemId: () => parent?.parentMemId,
        childMemIds: () => [
          for (final child in children) child.memId,
        ],
      ),
    ]);
  }

  MemEntity? _entity(int id) {
    for (final entity in state) {
      if (entity.id == id) return entity;
    }
    return null;
  }

  // ship は親リンクを含まない。取得済みのリンクを後から来た ship で消さない
  MemEntity _keepingLoadedParents(MemEntity shipped) {
    if (shipped.parentsLoaded) return shipped;
    final existing = _entity(shipped.id);
    if (existing == null || !existing.parentsLoaded) return shipped;
    return shipped.updatedWith(
      parentsLoaded: () => true,
      parentMemId: () => existing.parentMemId,
      childMemIds: () => existing.childMemIds,
    );
  }

  Future<void> _refreshParentMemIdsWithUndoneChildren() =>
      ref.read(parentMemIdsWithUndoneChildrenProvider.notifier).refresh();
}

@Riverpod(keepAlive: true)
class ParentMemIdsWithUndoneChildren extends _$ParentMemIdsWithUndoneChildren {
  @override
  Set<int> build() => const <int>{};

  Future<void> refresh() => v(
        () async {
          state = await MemRepository().shipParentMemIdsWithUndoneChildren();
        },
      );
}
