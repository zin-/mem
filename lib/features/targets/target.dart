import 'package:mem/features/acts/line_chart/states.dart';

enum TargetType { equalTo, lessThan, moreThan }

enum TargetUnit { count, time }

class Target {
  final int? memId;
  final TargetType targetType;
  final TargetUnit targetUnit;
  final int value;
  final Period period;
  final int? secondsAfterLastAct;

  Target({
    required this.memId,
    required this.targetType,
    required this.targetUnit,
    required this.value,
    required this.period,
    this.secondsAfterLastAct,
  });

  // 1日に2回以上の回数目標だけ、前回の終了からの間隔を持つ
  bool get acceptsSecondsAfterLastAct =>
      targetUnit == TargetUnit.count && period == Period.aDay && value >= 2;
}
