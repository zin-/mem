import 'package:mem/acts/line_chart/states.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'target_states.g.dart';

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
      state.value?.updatedWith(
            (v) => Target(
              memId: v.memId,
              targetType: targetType?.call() ?? v.targetType,
              targetUnit: targetUnit?.call() ?? v.targetUnit,
              value: value?.call() ?? v.value,
              period: period?.call() ?? v.period,
            ),
          ) ??
          _initialTarget(memId),
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
