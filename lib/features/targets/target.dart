import 'package:mem/features/acts/line_chart/states.dart';

enum TargetType { equalTo, lessThan, moreThan }

enum TargetUnit { count, time }

class Target {
  final int? memId;
  final TargetType targetType;
  final TargetUnit targetUnit;
  final int value;
  final Period period;

  Target({
    required this.memId,
    required this.targetType,
    required this.targetUnit,
    required this.value,
    required this.period,
  });
}
