import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/day_act_amount.dart';
import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/features/acts/target_ratio_label.dart';
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

class DayTargetLabel extends StatelessWidget {
  final Target _target;
  final DayActAmount _amount;
  final Act? _act;
  final String? _periodLabel;

  const DayTargetLabel(
    this._target,
    this._amount,
    this._act, {
    String? periodLabel,
    super.key,
  }) : _periodLabel = periodLabel;

  static bool shows(Target? target) => target != null && target.value > 0;

  @override
  Widget build(BuildContext context) => v(
        () {
          final act = _act;
          return switch (_target.targetUnit) {
            TargetUnit.count => TargetRatioLabel(
                current: _amount.count.toString(),
                target: _target.value.toString(),
                periodLabel: _periodLabel,
              ),
            TargetUnit.time => _TimeTargetLabel(
                _amount.recorded,
                // 一時停止してからの時間は作業時間ではない
                act is ActiveAct ? act.period?.start : null,
                _target.value,
                _periodLabel,
              ),
          };
        },
        {
          '_target': _target,
          '_amount': _amount,
          '_act': _act,
          '_periodLabel': _periodLabel,
        },
      );
}

class ActStatusLabels extends StatelessWidget {
  final Act? _act;
  final Target? _target;
  final DayActAmount? _amount;
  final Widget? _leading;
  final Widget? _time;
  final bool _centerTime;
  final String? _periodLabel;

  const ActStatusLabels(
    this._act,
    this._target,
    this._amount, {
    Widget? leading,
    Widget? time,
    bool centerTime = true,
    String? periodLabel,
    super.key,
  })  : _leading = leading,
        _time = time,
        _centerTime = centerTime,
        _periodLabel = periodLabel;

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
          '_periodLabel': _periodLabel,
        },
      );

  Widget? _timeLabel() {
    final target = _target;
    final amount = _amount;
    final children = <Widget>[
      if (_time != null) _time,
      if (target != null &&
          amount != null &&
          DayTargetLabel.shows(target) &&
          target.targetUnit == TargetUnit.time)
        DayTargetLabel(target, amount, _act, periodLabel: _periodLabel),
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

  Widget? _countLabel() {
    final target = _target;
    final amount = _amount;
    if (target == null ||
        amount == null ||
        !DayTargetLabel.shows(target) ||
        target.targetUnit != TargetUnit.count) {
      return null;
    }
    return DayTargetLabel(target, amount, _act, periodLabel: _periodLabel);
  }
}

class _TimeTargetLabel extends StatefulWidget {
  final Duration _recorded;
  final DateTime? _runningSince;
  final int _targetSeconds;
  final String? _periodLabel;

  const _TimeTargetLabel(
    this._recorded,
    this._runningSince,
    this._targetSeconds,
    this._periodLabel,
  );

  @override
  State<_TimeTargetLabel> createState() => _TimeTargetLabelState();
}

class _TimeTargetLabelState extends State<_TimeTargetLabel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant _TimeTargetLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._runningSince != widget._runningSince) {
      _timer?.cancel();
      _timer = null;
      _arm();
    }
  }

  void _arm() {
    if (widget._runningSince == null) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => v(
        () {
          final since = widget._runningSince;
          final current = widget._recorded +
              (since == null
                  ? Duration.zero
                  : DateTime.now().difference(since));
          return TargetRatioLabel(
            current: current.formatHHmm(),
            target: Duration(seconds: widget._targetSeconds).formatHHmm(),
            periodLabel: widget._periodLabel,
          );
        },
        {
          '_recorded': widget._recorded,
          '_runningSince': widget._runningSince,
          '_targetSeconds': widget._targetSeconds,
          '_periodLabel': widget._periodLabel,
        },
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
