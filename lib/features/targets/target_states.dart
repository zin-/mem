import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'target_states.g.dart';

@riverpod
class Targets extends _$Targets {
  final Set<int> _requestedMemIds = {};

  @override
  List<SavedTargetEntityV1> build() => v(
        () {
          _requestedMemIds.clear();
          return [];
        },
      );

  Future<void> fetchByMemIds(Iterable<int> memIds) => v(
        () async {
          final newMemIds =
              memIds.where((id) => !_requestedMemIds.contains(id)).toList();
          if (newMemIds.isEmpty) return;

          final targets = await TargetRepository().shipByMemIds(newMemIds).then(
                (rows) => rows.map(SavedTargetEntityV1.fromEntityV2).toList(),
              );

          if (!ref.mounted) return;

          _requestedMemIds.addAll(newMemIds);
          if (targets.isEmpty) return;

          final loadedMemIds = targets.map((e) => e.value.memId).toSet();
          state = [
            ...state.where((e) => !loadedMemIds.contains(e.value.memId)),
            ...targets,
          ];
        },
        {
          'memIds': memIds,
        },
      );

  void upsert(SavedTargetEntityV1 target) => v(
        () {
          final memId = target.value.memId;
          if (memId != null) {
            _requestedMemIds.add(memId);
          }
          state = [
            ...state.where((e) => e.value.memId != target.value.memId),
            target,
          ];
        },
        {
          'memId': target.value.memId,
        },
      );

  void removeByMemId(int memId) => v(
        () {
          _requestedMemIds.add(memId);
          state = [
            for (final target in state)
              if (target.value.memId != memId) target,
          ];
        },
        {
          'memId': memId,
        },
      );
}

@riverpod
class TargetState extends _$TargetState {
  @override
  Future<TargetEntityV1> build(int? memId) async {
    if (memId != null) {
      final targets = await TargetRepository()
          .shipByMemId(memId)
          .then((v) => v.map((e) => SavedTargetEntityV1.fromEntityV2(e)));
      if (targets.isNotEmpty) {
        return targets.first;
      }
    }

    return _initialTarget(memId);
  }

  void updatedWith({
    TargetType? Function()? targetType,
    TargetUnit? Function()? targetUnit,
    int? Function()? value,
    Period? Function()? period,
  }) {
    state = AsyncData(
      state.requireValue.updatedWith(
        (v) => Target(
          memId: v.memId,
          targetType: targetType?.call() ?? v.targetType,
          targetUnit: targetUnit?.call() ?? v.targetUnit,
          value: value?.call() ?? v.value,
          period: period?.call() ?? v.period,
        ),
      ),
    );
  }

  TargetEntityV1 _initialTarget(int? memId) => TargetEntityV1(
        Target(
          memId: memId,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: 0,
          period: Period.aDay,
        ),
      );
}
