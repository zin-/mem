import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/view/identifiable.dart';

mixin EntitiesStateMixinV1<T extends Identifiable<PK>, PK>
    on AnyNotifier<Iterable<T>, Iterable<T>> {
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
