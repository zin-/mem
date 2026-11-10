import 'package:collection/collection.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_client.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
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

  Future<MemEntity> loadByMemId(int memId) => v(
        () async {
          final mem = await MemRepository().shipById(
            memId,
            loadLatestAct: true,
          );

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
          final rows = await MemRepository().ship(
            id: memId,
            loadLatestAct: true,
          );
          if (rows.isEmpty) return;
          upsert([rows.single]);
        },
        {'memId': memId},
      );

  Future<Iterable<MemEntity>> removeAsync(Iterable<int> ids) => v(
        () async {
          await Future.wait(ids.map((id) => MemClient().remove(id)));

          final removed = remove(ids);
          await _refreshParentMemIdsWithUndoneChildren();
          return removed;
        },
        {'ids': ids},
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

  Future<void> _fetchDetail(int memId) async {
    final repository = MemRepository();
    final mem = await repository.shipById(memId, loadLatestAct: true);
    final parent = await repository.shipParentByMemId(memId);
    final children = await repository.shipChildrenByParentMemId(memId);

    final relatedIds = <int>{
      if (parent != null) parent.parentMemId,
      for (final child in children) child.memId,
    };
    final missing = <MemEntity>[];
    for (final id in relatedIds) {
      if (id == memId || _entity(id) != null) continue;
      missing.add(await repository.shipById(id));
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
