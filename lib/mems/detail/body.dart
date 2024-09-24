import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/date_and_time/created_and_updated_at_texts.dart';
import 'package:mem/mems/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/notifications/mem_notifications_view.dart';
import 'package:mem/mems/mem_done_checkbox.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/mems/mem_name.dart';
import 'package:mem/mems/mem_period.dart';
import 'package:mem/values/dimens.dart';

import 'mem_items_view.dart';

class MemDetailBody extends ConsumerWidget {
  final int? _memId;

  const MemDetailBody(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final editingMem = ref.watch(editingMemByMemIdProvider(_memId));

          return _MemDetailBodyComponent(
            _memId,
            editingMem,
            (value) =>
                ref.read(editingMemByMemIdProvider(_memId).notifier).updatedBy(
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
  final Mem _mem;
  final Function(bool? memDone) _onMemDoneChanged;

  const _MemDetailBodyComponent(
    this._memId,
    this._mem,
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
                      MemNameTextFormField(_memId),
                      MemDoneCheckbox(
                        _mem,
                        _onMemDoneChanged,
                      ),
                      MemPeriodTextFormFields(_memId),
                      MemNotificationsView(_memId),
                      MemItemsFormFields(_memId),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: pageBottomPadding,
              child: CreatedAndUpdatedAtTexts(
                _mem,
              ),
            ),
          ],
        ),
        {
          "_memId": _memId,
          "_mem": _mem,
        },
      );
}
