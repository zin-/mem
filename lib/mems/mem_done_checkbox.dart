import 'package:flutter/material.dart';
import 'package:mem/framework/view/hero_view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_entity.dart';

class MemDoneCheckbox extends StatelessWidget {
  final MemEntityV2 _memEntity;
  final Function(bool? value) _onChanged;

  const MemDoneCheckbox(
    this._memEntity,
    this._onChanged, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () => HeroView(
          heroTag(
            'mem-done',
            _memEntity is SavedMemEntityV2 ? _memEntity.id : null,
          ),
          Checkbox(
            value: _memEntity.value.isDone,
            onChanged:
                (_memEntity is SavedMemEntityV2 ? _memEntity.isArchived : false)
                    ? null
                    : _onChanged,
          ),
        ),
        {
          '_memEntity': _memEntity,
        },
      );
}
