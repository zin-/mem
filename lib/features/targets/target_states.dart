import 'package:mem/acts/line_chart/states.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'target_states.g.dart';

@riverpod
class TargetState extends _$TargetState {
  @override
  TargetEntity build(int? memId) {
    return TargetEntity(
      Target(
        memId: memId,
        targetType: TargetType.equalTo,
        targetUnit: TargetUnit.count,
        value: 10,
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
