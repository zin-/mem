import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/entity.dart';

import 'target.dart';
import 'target_table.dart';

class TargetEntity with Entity<Target> {
  TargetEntity(Target value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        defFkTargetMemId.name: value.memId,
        defColTargetType.name: value.targetType.name,
        defColTargetUnit.name: value.targetUnit.name,
        defColTargetValue.name: value.value,
        defColTargetPeriod.name: value.period.name,
      };

  @override
  TargetEntity updatedWith(Target Function(Target v) update) =>
      TargetEntity(update(value));
}

class SavedTargetEntity extends TargetEntity
    with DatabaseTupleEntityV2<int, Target> {
  SavedTargetEntity(Map<String, dynamic> map)
      : super(
          Target(
            memId: map[defFkTargetMemId.name],
            targetType: TargetType.values.firstWhere(
              (element) => element.name == map[defColTargetType.name],
            ),
            targetUnit: TargetUnit.values.firstWhere(
              (element) => element.name == map[defColTargetUnit.name],
            ),
            value: map[defColTargetValue.name],
            period: Period.values.firstWhere(
              (element) => element.name == map[defColTargetPeriod.name],
            ),
          ),
        ) {
    withMap(map);
  }

  @override
  SavedTargetEntity updatedWith(Target Function(Target v) update) =>
      SavedTargetEntity(toMap..addAll(super.updatedWith(update).toMap));
}
