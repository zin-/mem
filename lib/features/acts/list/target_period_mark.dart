import 'package:mem/features/acts/line_chart/states.dart';

class TargetPeriodMark {
  final String text;

  // まとめ単位より長い目標は、行に載っていない期間を問い合わせる
  final bool queries;

  const TargetPeriodMark._(this.text, this.queries);

  static TargetPeriodMark? of({
    required Period group,
    required Period target,
  }) {
    if (group == target) return null;
    return TargetPeriodMark._(
      _text(target),
      // Period の宣言順は短い期間から
      target.index > group.index,
    );
  }

  static String _text(Period period) => switch (period) {
        Period.aDay => 'd',
        Period.aWeek => 'w',
        Period.aMonth => 'm',
        Period.threeMonth => '3m',
        Period.aYear => 'y',
        Period.all => 'all',
      };
}
