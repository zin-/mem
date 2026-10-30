import 'package:mem/features/targets/target.dart';

class CountTarget {
  final Target target;
  final int count;

  CountTarget._(this.target, this.count);

  static CountTarget? of(Target? target, int count) {
    if (target == null ||
        target.targetUnit != TargetUnit.count ||
        target.value <= 0) {
      return null;
    }
    return CountTarget._(target, count);
  }

  int get targetValue => target.value;
}
