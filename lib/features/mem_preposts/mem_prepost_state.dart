import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_preposts/mem_prepost_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mem_prepost_state.g.dart';

@riverpod
class MemPrePostEntitiesByMemId extends _$MemPrePostEntitiesByMemId {
  @override
  Future<Iterable<MemPrePostEntityV1>> build(int? memId) => v(
        () async {
          if (memId == null) {
            return [];
          }

          return (await MemRepository().shipPrePostsBySourceMemId(memId))
              .map(SavedMemPrePostEntityV1.fromEntityV2);
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
