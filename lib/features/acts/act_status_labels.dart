import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_amount.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/target_progress_label.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/modules/live_elapsed_time_text.dart';
import 'package:mem/values/dimens.dart';

class StateElapsedTime extends StatelessWidget {
  final Act? _act;

  const StateElapsedTime(this._act, {super.key});

  static bool shows(Act? act) => _startOf(act) != null;

  static DateTime? _startOf(Act? act) => switch (act) {
        ActiveAct() => act.period?.start,
        PausedAct() => act.pausedAt,
        _ => null,
      };

  @override
  Widget build(BuildContext context) => v(
        () {
          final start = _startOf(_act);
          if (start == null) {
            return const SizedBox.shrink();
          }
          return LiveElapsedTimeText(start);
        },
        {'_act': _act},
      );
}

class ActStatusLabels extends StatelessWidget {
  final Act? _act;
  final Target? _target;
  final ActAmount? _amount;
  final Widget? _leading;
  final Widget? _time;
  final bool _centerTime;
  final Period _shownIn;

  const ActStatusLabels(
    this._act,
    this._target,
    this._amount, {
    Widget? leading,
    Widget? time,
    bool centerTime = true,
    required Period shownIn,
    super.key,
  })  : _leading = leading,
        _time = time,
        _centerTime = centerTime,
        _shownIn = shownIn;

  @override
  Widget build(BuildContext context) => v(
        () {
          final time = _timeLabel();
          final count = _countLabel();
          final leading = _leading;
          if (time == null && count == null) {
            return leading ?? const SizedBox.shrink();
          }
          // 件数目標は右端。Mem 一覧の時間は中央、Act 一覧の時間は左
          if (time == null) {
            return Row(
              children: [
                Expanded(child: leading ?? const SizedBox.shrink()),
                count!,
              ],
            );
          }
          if (!_centerTime) {
            return Row(
              children: [
                if (leading != null) leading,
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: time,
                  ),
                ),
                if (count != null) count,
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: leading ?? const SizedBox.shrink(),
                ),
              ),
              time,
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: count ?? const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
        {
          '_act': _act,
          '_target': _target,
          '_amount': _amount,
          '_shownIn': _shownIn,
        },
      );

  Widget? _timeLabel() {
    final progress = _progressLabel(TargetUnit.time);
    final children = <Widget>[
      if (_time != null) _time,
      if (progress != null) progress,
      if (StateElapsedTime.shows(_act)) StateElapsedTime(_act),
    ];
    if (children.isEmpty) {
      return null;
    }
    return Wrap(
      spacing: defaultComponentPadding,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  Widget? _countLabel() => _progressLabel(TargetUnit.count);

  Widget? _progressLabel(TargetUnit unit) {
    final target = _target;
    final amount = _amount;
    if (target == null ||
        amount == null ||
        !TargetProgressLabel.shows(target) ||
        target.targetUnit != unit) {
      return null;
    }
    return TargetProgressLabel(
      amount,
      target,
      shownIn: _shownIn,
      act: _act,
    );
  }
}
