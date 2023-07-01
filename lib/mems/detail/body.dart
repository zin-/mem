import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/repeated_notification_view.dart';
import 'package:mem/mems/mem_done_checkbox.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_name.dart';
import 'package:mem/mems/mem_period.dart';

import 'mem_items_view.dart';

class MemDetailBody extends ConsumerWidget {
  final int? _memId;

  const MemDetailBody(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final editingMem = ref.watch(editingMemProvider(_memId));

          return _MemDetailBodyComponent(
            _memId,
            editingMem,
            (value) => ref.read(editingMemProvider(_memId).notifier).updatedBy(
                  editingMem.copied()..name = value,
                ),
            (value) => ref.read(editingMemProvider(_memId).notifier).updatedBy(
                  editingMem.copied()
                    ..doneAt = value == true ? DateTime.now() : null,
                ),
          );
        },
        _memId.toString(),
      );
}

class _MemDetailBodyComponent extends StatelessWidget {
  final int? _memId;
  final Mem _mem;
  final Function(String memName) _onMemNameChanged;
  final Function(bool? memDone) _onMemDoneChanged;

  const _MemDetailBodyComponent(
    this._memId,
    this._mem,
    this._onMemNameChanged,
    this._onMemDoneChanged,
  );

  @override
  Widget build(BuildContext context) => v(
        () => SingleChildScrollView(
          child: Column(
            children: [
              MemNameTextFormField(
                _mem.name,
                _memId,
                _onMemNameChanged,
              ),
              MemDoneCheckbox(
                _mem,
                _onMemDoneChanged,
              ),
              MemPeriodTextFormFields(_memId),
              RepeatedNotificationWidget(_memId),
              MemItemsFormFields(_memId),
            ],
          ),
        ),
        {_memId.toString(), _mem},
      );
}
