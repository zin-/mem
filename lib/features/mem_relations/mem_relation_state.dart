import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/shared/entities_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mem_relation_state.g.dart';

@riverpod
class MemRelationEntities extends _$MemRelationEntities
    with EntitiesStateMixinV1<SavedMemRelationEntityV1, int> {
  @override
  Iterable<SavedMemRelationEntityV1> build() => v(() => []);
}

@riverpod
class MemRelationEntitiesByMemId extends _$MemRelationEntitiesByMemId {
  @override
  Future<Iterable<MemRelationEntityV1>> build(int? memId) => v(
        () async {
          if (memId == null) {
            return [];
          }

          final currentEntities = ref.watch(memRelationEntitiesProvider);
          final fetchedEntities = (await MemRelationRepository()
                  .shipBySourceMemIdV2(memId))
              .map((e) => SavedMemRelationEntityV1.fromEntityV2(e))
              .toList();

          if (fetchedEntities.isNotEmpty &&
              !currentEntities
                  .every((e) => fetchedEntities.any((ee) => ee.id == e.id))) {
            ref
                .watch(memRelationEntitiesProvider.notifier)
                .upsert(fetchedEntities);
          }

          return [...currentEntities, ...fetchedEntities];
        },
        {'memId': memId},
      );

  Future<Iterable<MemRelationEntityV1>> upsert(
    Iterable<MemRelationEntityV1> entities,
  ) async =>
      v(
        () async {
          state = AsyncValue.data([
            ...(state.value ?? []).where(
                (e) => e.value.targetMemId != entities.first.value.targetMemId),
            ...entities,
          ]);
          return state.value ?? [];
        },
        {'entities': entities},
      );
}
