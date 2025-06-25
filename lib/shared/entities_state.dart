import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

mixin EntitiesStateMixin<T extends DatabaseTupleEntityV2<PK, dynamic>, PK>
    on AutoDisposeNotifier<Iterable<T>> {
  Iterable<T> upsert(Iterable<T> entities) => v(
        () {
          state = [
            ...state.where((existing) =>
                !entities.any((newEntity) => newEntity.id == existing.id)),
            ...entities,
          ];

          return state;
        },
        {
          'currentState': state,
          'entities': entities,
        },
      );

  Iterable<T> remove(Iterable<PK> ids) => v(
        () {
          final removed = state.where((e) => ids.contains(e.id));
          state = state.where((e) => !ids.contains(e.id)).toList();

          return removed;
        },
        {
          'currentState': state,
          'ids': ids,
        },
      );
}
