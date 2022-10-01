import 'package:flutter/material.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/atoms/hero_view.dart';

class MemDoneCheckbox extends StatelessWidget {
  final int? _memId;
  final bool _memDone;
  final Function(bool? value) _onChanged;

  const MemDoneCheckbox(
    this._memId,
    this._memDone,
    this._onChanged, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {'_memId': _memId, '_memDone': _memDone, '_onChanged': _onChanged},
        () => HeroView(
          heroTag('mem-done', _memId),
          Checkbox(
            value: _memDone,
            onChanged: (value) => _onChanged(value),
          ),
        ),
      );
}
