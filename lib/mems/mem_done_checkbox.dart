import 'package:flutter/material.dart';
import 'package:mem/mems/mem.dart';
import 'package:mem/framework/view/hero_view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_entity.dart';

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
          heroTag(
            'mem-done',
            _mem is SavedMemEntity ? _mem.id : null,
          ),
          Checkbox(
            value: _mem.isDone,
            onChanged: (_mem is SavedMemEntity ? _mem.isArchived : false)
                ? null
                : _onChanged,
          ),
        ),
        {
          '_mem': _mem,
        },
      );
}
