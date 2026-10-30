import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_count_label.dart';
import 'package:mem/features/acts/day_act_amount.dart';
import 'package:mem/features/acts/list/duration.dart';
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

  const DayTargetLabel(this._target, this._amount, this._act, {super.key});

  static bool shows(Target? target) => target != null && target.value > 0;

  @override
  Widget build(BuildContext context) => v(
        () {
          final act = _act;
          return switch (_target.targetUnit) {
            TargetUnit.count => ActCountLabel(_amount.count, _target.value),
            TargetUnit.time => _TimeTargetLabel(
                _amount.recorded,
                // 一時停止してからの時間は作業時間ではない
                act is ActiveAct ? act.period?.start : null,
                _target.value,
              ),
          };
        },
        {
          '_target': _target,
          '_amount': _amount,
          '_act': _act,
        },
      );
}

class ActStatusLabels extends StatelessWidget {
  final Act? _act;
  final Target? _target;
  final DayActAmount? _amount;

  const ActStatusLabels(this._act, this._target, this._amount, {super.key});

  static bool shows(Act? act, Target? target, DayActAmount? amount) =>
      StateElapsedTime.shows(act) ||
      (DayTargetLabel.shows(target) && amount != null);

  @override
  Widget build(BuildContext context) => v(
        () => Wrap(
          spacing: defaultComponentPadding,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 状態時間は LiveElapsedTimeText があった右端に残す
            if (DayTargetLabel.shows(_target) && _amount != null)
              DayTargetLabel(_target!, _amount, _act),
            if (StateElapsedTime.shows(_act)) StateElapsedTime(_act),
          ],
        ),
        {
          '_act': _act,
          '_target': _target,
          '_amount': _amount,
        },
      );
}

class _TimeTargetLabel extends StatefulWidget {
  final Duration _recorded;
  final DateTime? _runningSince;
  final int _targetSeconds;

  const _TimeTargetLabel(
      this._recorded, this._runningSince, this._targetSeconds);

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
          return Wrap(
            children: [
              Text(current.formatHHmm()),
              const Text(' / '),
              Text(Duration(seconds: widget._targetSeconds).formatHHmm()),
            ],
          );
        },
        {
          '_recorded': widget._recorded,
          '_runningSince': widget._runningSince,
          '_targetSeconds': widget._targetSeconds,
        },
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
