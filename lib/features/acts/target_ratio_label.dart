import 'package:flutter/material.dart';
import 'package:mem/features/logger/log_service.dart';

class TargetRatioLabel extends StatelessWidget {
  final String _current;
  final String _target;
  final String? _periodLabel;

  const TargetRatioLabel({
    required String current,
    required String target,
    String? periodLabel,
    super.key,
  })  : _current = current,
        _target = target,
        _periodLabel = periodLabel;

  @override
  Widget build(BuildContext context) => v(
        () {
          const separator = Text(' / ');
          final periodLabel = _periodLabel;
          return Wrap(
            children: [
              Text(_current),
              separator,
              Text(_target),
              if (periodLabel != null) ...[
                separator,
                Text(periodLabel),
              ],
            ],
          );
        },
        {
          '_current': _current,
          '_target': _target,
          '_periodLabel': _periodLabel,
        },
      );
}
