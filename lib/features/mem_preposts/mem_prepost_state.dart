import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_preposts/mem_prepost_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/shared/entities_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mem_prepost_state.g.dart';

@riverpod
class MemPrePostEntities extends _$MemPrePostEntities
    with EntitiesStateMixinV1<SavedMemPrePostEntityV1, int> {
  @override
  Iterable<SavedMemPrePostEntityV1> build() => v(() => []);
}

@riverpod
class MemPrePostEntitiesByMemId extends _$MemPrePostEntitiesByMemId {
  @override
  Future<Iterable<MemPrePostEntityV1>> build(int? memId) => v(
        () async {
          if (memId == null) {
            return [];
          }

          final currentEntities = ref.watch(memPrePostEntitiesProvider);
          final fetchedEntities =
              (await MemRepository().shipPrePostsBySourceMemId(memId))
                  .map(SavedMemPrePostEntityV1.fromEntityV2)
                  .toList();

          if (fetchedEntities.isNotEmpty &&
              !currentEntities
                  .every((e) => fetchedEntities.any((ee) => ee.id == e.id))) {
            ref
                .watch(memPrePostEntitiesProvider.notifier)
                .upsert(fetchedEntities);
          }

          return [...currentEntities, ...fetchedEntities];
        },
        {'memId': memId},
      );

  Future<Iterable<MemPrePostEntityV1>> upsert(
    Iterable<MemPrePostEntityV1> entities,
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
