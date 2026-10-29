import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/targets/target.dart';

class CountTarget {
  final Mem mem;
  final Target target;
  final Iterable<Act> actsInPeriod;

  CountTarget._(this.mem, this.target, this.actsInPeriod);

  static CountTarget? of(
    Mem mem,
    Target? target,
    Iterable<Act> actsInPeriod,
  ) {
    if (target == null ||
        target.targetUnit != TargetUnit.count ||
        target.value <= 0) {
      return null;
    }
    return CountTarget._(mem, target, actsInPeriod);
  }

  int get count => actsInPeriod.length;

  int get targetValue => target.value;
}
