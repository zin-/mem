import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem_detail.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/states.dart';
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

  Future<MemDetail?> undoRemove(int id) => v(
        () async {
          // ignore: avoid_manual_providers_as_generated_provider_dependency
          final removedMemDetail = ref.read(removedMemDetailProvider(id));

          if (removedMemDetail != null) {
            // FIXME serviceを利用しているが、clientを利用するべきでは？
            // FIXME ここでserviceの初期化をしているが、stateをbuildしたタイミングでseviceの初期化もしたい
            //   repositoryの親子関係解決を確定するタイミングの問題で、現時点ではここで初期化する必要がある
            //   https://github.com/zin-/mem/issues/472
            final undoneRemovedMemDetail =
                await MemService().save(removedMemDetail, undo: true);

            state = [
              ...state,
              undoneRemovedMemDetail.mem as SavedMemEntityV2,
            ];

            return undoneRemovedMemDetail;
          }

          return null;
        },
        {'id': id},
      );
}
