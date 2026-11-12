import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_amount.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/features/acts/period_view.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/targets/target.dart';

const _tickInterval = Duration(seconds: 1);

class TargetProgressLabel extends StatefulWidget {
  final ActAmount _amount;
  final Target _target;
  final Period _shownIn;
  final Act? _act;

  const TargetProgressLabel(
    this._amount,
    this._target, {
    required Period shownIn,
    Act? act,
    super.key,
  })  : _shownIn = shownIn,
        _act = act;

  static bool shows(Target? target) => target != null && target.value > 0;

  // 一時停止してからの時間は作業時間ではない
  DateTime? _runningSince() {
    final act = _act;
    return switch (act) {
      ActiveAct() => act.period?.start,
      _ => null,
    };
  }

  String _currentText(DateTime now) => switch (_target.targetUnit) {
        TargetUnit.count => _amount.count.toString(),
        TargetUnit.time => _recordedAt(now).formatHHmm(),
      };

  String _targetText() => switch (_target.targetUnit) {
        TargetUnit.count => _target.value.toString(),
        TargetUnit.time => Duration(seconds: _target.value).formatHHmm(),
      };

  Duration _recordedAt(DateTime now) {
    final since = _runningSince();
    if (since == null) {
      return _amount.recorded;
    }
    return _amount.recorded + now.difference(since);
  }

  String? _periodLabel() {
    final period = _target.period;
    if (period == _shownIn) {
      return null;
    }
    return period.shortLabel;
  }

  @override
  State<TargetProgressLabel> createState() => _TargetProgressLabelState();
}

class _TargetProgressLabelState extends State<TargetProgressLabel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant TargetProgressLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._runningSince() != widget._runningSince() ||
        oldWidget._target.targetUnit != widget._target.targetUnit) {
      _timer?.cancel();
      _timer = null;
      _arm();
    }
  }

  void _arm() {
    if (widget._target.targetUnit != TargetUnit.time ||
        widget._runningSince() == null) {
      return;
    }
    _timer = Timer.periodic(_tickInterval, (_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => v(
        () {
          const separator = Text(' / ');
          final periodLabel = widget._periodLabel();
          return Wrap(
            children: [
              Text(widget._currentText(DateTime.now())),
              separator,
              Text(widget._targetText()),
              if (periodLabel != null) ...[
                separator,
                Text(periodLabel),
              ],
            ],
          );
        },
        {
          '_amount': widget._amount,
          '_target': widget._target,
          '_shownIn': widget._shownIn,
          '_act': widget._act,
        },
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
