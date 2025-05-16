import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/states.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mems_state.g.dart';

@riverpod
class MemEntities extends _$MemEntities {
  @override
  Iterable<SavedMemEntityV2> build() {
    // tmp
    // ignore: avoid_manual_providers_as_generated_provider_dependency
    return ref.watch(memsProvider).whereType<SavedMemEntityV2>();
  }

  void upsert(Iterable<SavedMemEntityV2> mems) {
    state = [
      ...state.where((e) => !mems.any((m) => m.id == e.id)),
      ...mems,
    ];

    // tmp
    // ignore: avoid_manual_providers_as_generated_provider_dependency
    ref.read(memsProvider.notifier).upsertAll(
          mems,
          (current, updating) =>
              current is SavedMemEntityV2 &&
              updating is SavedMemEntityV2 &&
              current.id == updating.id,
        );
  }

  void remove(Iterable<int> ids) {
    state = state.where((e) => !ids.contains(e.id)).toList();

    // tmp
    // ignore: avoid_manual_providers_as_generated_provider_dependency
    ref.read(memsProvider.notifier).removeWhere(
          (element) => element is SavedMemEntityV2 && ids.contains(element.id),
        );
  }
}
