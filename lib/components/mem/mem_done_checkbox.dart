import 'package:flutter/material.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/components/hero_view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem.dart';

class MemDoneCheckbox extends StatelessWidget {
  final MemV1 _mem;
  final Function(bool? value) _onChanged;

  const MemDoneCheckbox(
    this._mem,
    this._onChanged, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () => HeroView(
          heroTag(
            'mem-done',
            _mem is SavedMemV1 ? _mem.id : null,
          ),
          Checkbox(
            value: _mem.isDone,
            onChanged: (_mem is SavedMemV1 ? _mem.isArchived : false)
                ? null
                : _onChanged,
          ),
        ),
        {
          '_mem': _mem,
        },
      );
}
