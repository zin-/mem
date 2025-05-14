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
  TargetEntity build(int? memId) {
    if (memId != null) {
      TargetRepository()
          .ship(condition: Equals(defFkTargetMemId, memId))
          .then((value) {
        if (value.isNotEmpty) {
          state = value.first;
        }
      });
    }

    return TargetEntity(
      Target(
        memId: memId,
        targetType: TargetType.equalTo,
        targetUnit: TargetUnit.count,
        value: 0,
        period: Period.aDay,
      ),
    );
  }

  TargetEntity updatedWith({
    TargetType? Function()? targetType,
    TargetUnit? Function()? targetUnit,
    int? Function()? value,
    Period? Function()? period,
  }) {
    state = state.updatedWith(
      (v) => Target(
        memId: v.memId,
        targetType: targetType?.call() ?? v.targetType,
        targetUnit: targetUnit?.call() ?? v.targetUnit,
        value: value?.call() ?? v.value,
        period: period?.call() ?? v.period,
      ),
    );

    return state;
  }
}
