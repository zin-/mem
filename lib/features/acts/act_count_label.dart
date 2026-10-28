import 'package:flutter/material.dart';
import 'package:mem/features/logger/log_service.dart';

class ActCountLabel extends StatelessWidget {
  final int _count;
  final int? _target;

  const ActCountLabel(this._count, this._target, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () => Wrap(
          children: [
            Text(_count.toString()),
            if (_target != null) ...[
              const Text(' / '),
              Text(_target.toString()),
            ],
          ],
        ),
        {
          '_count': _count,
          '_target': _target,
        },
      );
}
