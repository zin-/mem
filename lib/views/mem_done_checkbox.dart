import 'package:flutter/material.dart';
import 'package:mem/logger.dart';

class MemDoneCheckbox extends StatelessWidget {
  final bool _memDone;
  final Function(bool? value) _onChanged;

  const MemDoneCheckbox(this._memDone, this._onChanged, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {'_memDone': _memDone, '_onChanged': _onChanged},
        () => Checkbox(
          value: _memDone,
          onChanged: (value) => _onChanged(value),
        ),
      );
}
