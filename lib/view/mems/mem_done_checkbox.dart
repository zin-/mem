import 'package:flutter/material.dart';
import 'package:mem/domain/mem.dart';
import 'package:mem/logger.dart';
import 'package:mem/view/atoms/hero_view.dart';

class MemDoneCheckbox extends StatelessWidget {
  final Mem _mem;
  final Function(bool? value) _onChanged;

  const MemDoneCheckbox(
    this._mem,
    this._onChanged, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        {
          '_mem': _mem,
          '_onChanged': _onChanged,
        },
        () => HeroView(
          heroTag('mem-done', _mem.id),
          Checkbox(
            value: _mem.isDone(),
            onChanged: _mem.isArchived() ? null : (value) => _onChanged(value),
            // onChanged: (value) => _onChanged(value),
          ),
        ),
      );
}
