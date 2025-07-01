import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/shared/entities_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mem_relation_state.g.dart';

@riverpod
class MemRelationEntities extends _$MemRelationEntities
    with EntitiesStateMixin<SavedMemRelationEntity, int> {
  @override
  Iterable<SavedMemRelationEntity> build() => v(() => []);
}

@riverpod
class MemRelationEntitiesByMemId extends _$MemRelationEntitiesByMemId {
  @override
  Iterable<MemRelationEntity> build(int? memId) => v(
        () {
          if (memId == null) {
            return [];
          }

          return ref.read(memRelationEntitiesProvider
              .select((v) => v.where((e) => e.value.sourceMemId == memId)));
        },
        {'memId': memId},
      );
}
