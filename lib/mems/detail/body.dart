import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/created_and_updated_at_texts.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/notifications_view.dart';
import 'package:mem/components/mem/mem_done_checkbox.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/components/mem/mem_name.dart';
import 'package:mem/components/mem/mem_period.dart';
import 'package:mem/values/dimens.dart';

import 'mem_items_view.dart';

class MemDetailBody extends ConsumerWidget {
  final int? _memId;

  const MemDetailBody(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final editingMem = ref.watch(memDetailProvider(_memId)).mem;

          return _MemDetailBodyComponent(
            _memId,
            editingMem,
            (value) => ref.read(editingMemProvider(_memId).notifier).updatedBy(
                  editingMem.copiedWith(name: () => value),
                ),
            (value) => ref.read(editingMemProvider(_memId).notifier).updatedBy(
                  editingMem.copiedWith(
                      doneAt: () => value == true ? DateTime.now() : null),
                ),
          );
        },
        _memId.toString(),
      );
}

class _MemDetailBodyComponent extends StatelessWidget {
  final int? _memId;
  final MemV2 _mem;
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
        () => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: pageTopPadding,
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
                      NotificationsWidget(_memId),
                      MemItemsFormFields(_memId),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: pageBottomPadding,
              child: CreatedAndUpdatedAtTexts(_mem.toV1()),
            ),
          ],
        ),
        {"memId": _memId.toString(), "_mem": _mem},
      );
}
