import 'package:flutter/material.dart';
import 'package:mem/features/logger/log_service.dart';

class ActCountLabel extends StatelessWidget {
  final int _count;
  final int? _target;
  final String? _unit;

  const ActCountLabel(this._count, this._target, {String? unit, super.key})
      : _unit = unit;

  @override
  Widget build(BuildContext context) => v(
        () => Wrap(
          children: [
            Text(_count.toString()),
            if (_target != null) ...[
              const Text(' / '),
              Text(_target.toString()),
              if (_unit != null) ...[
                const Text(' / '),
                Text(_unit),
              ],
            ],
          ],
        ),
        {
          '_count': _count,
          '_target': _target,
          '_unit': _unit,
        },
      );
}
