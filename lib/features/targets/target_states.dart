import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'target_states.g.dart';

@riverpod
class Targets extends _$Targets {
  @override
  List<SavedTargetEntity> build() => v(
        () => [],
      );

  fetchByMemIds(Iterable<int> memIds) => d(
        () async {
          final newMemIds =
              memIds.where((e) => !state.map((e) => e.value.memId).contains(e));

          if (newMemIds.isNotEmpty) {
            final targets = await TargetRepository()
                .ship(condition: In(defFkTargetMemId.name, newMemIds));

            if (targets.isNotEmpty) {
              state = [...state, ...targets];
            }
          }
        },
        {
          'memIds': memIds,
        },
      );
}

@riverpod
class TargetState extends _$TargetState {
  @override
  Future<TargetEntity> build(int? memId) async {
    if (memId != null) {
      final targets = await TargetRepository()
          .ship(condition: Equals(defFkTargetMemId, memId));
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

  TargetEntity _initialTarget(int? memId) => TargetEntity(
        Target(
          memId: memId,
          targetType: TargetType.equalTo,
          targetUnit: TargetUnit.count,
          value: 0,
          period: Period.aDay,
        ),
      );
}
