import 'package:mem/framework/repository/entity.dart';

import 'target.dart';

class TargetEntity with EntityV2<Target> {
  TargetEntity(Target value) {
    this.value = value;
  }

  @override
  Map<String, Object?> get toMap => {
        'mems_id': value.memId,
        'type': value.targetType.name,
        'unit': value.targetUnit.name,
        'value': value.value,
      };

  @override
  TargetEntity updatedWith(Target Function(Target v) update) =>
      TargetEntity(update(value));
}
