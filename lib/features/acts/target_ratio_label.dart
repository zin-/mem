import 'package:flutter/material.dart';
import 'package:mem/features/acts/list/target_period_mark.dart';
import 'package:mem/features/logger/log_service.dart';

class TargetRatioLabel extends StatelessWidget {
  final String _current;
  final String _target;
  final TargetPeriodMark? _mark;

  const TargetRatioLabel({
    required String current,
    required String target,
    TargetPeriodMark? mark,
    super.key,
  })  : _current = current,
        _target = target,
        _mark = mark;

  @override
  Widget build(BuildContext context) => v(
        () {
          const separator = Text(' / ');
          final mark = _mark;
          return Wrap(
            children: [
              Text(_current),
              separator,
              Text(_target),
              if (mark != null) ...[
                separator,
                Text(mark.text),
              ],
            ],
          );
        },
        {
          '_current': _current,
          '_target': _target,
          '_mark': _mark,
        },
      );
}
