import 'package:flutter/material.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/hero_view.dart';
import 'package:mem/logger/log_service_v2.dart';

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
        () => HeroView(
          heroTag('mem-done', _mem.id),
          Checkbox(
            value: _mem.isDone(),
            onChanged: _mem.isArchived() ? null : _onChanged,
          ),
        ),
        {
          '_mem': _mem,
          '_onChanged': _onChanged,
        },
      );
}
