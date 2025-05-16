import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mems_state.g.dart';

@riverpod
class MemEntities extends _$MemEntities {
  @override
  Iterable<SavedMemEntityV2> build() {
    return [];
  }

  void upsert(Iterable<SavedMemEntityV2> mems) => v(
        () {
          state = [
            ...state.where((e) => !mems.any((m) => m.id == e.id)),
            ...mems,
          ];
        },
        {'mems': mems},
      );

  void remove(Iterable<int> ids) => v(
        () {
          state = state.where((e) => !ids.contains(e.id)).toList();
        },
        {'ids': ids},
      );
}
