import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_actions.dart';
import 'package:mem/acts/act_list_page_states.dart';
import 'package:mem/components/date_and_time/date_and_time_period_view.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';

import 'states.dart';

class EditingActDialog extends ConsumerWidget {
  final Act _act;

  const EditingActDialog(this._act, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actId = ActIdentifier(_act.id!, _act.memId);
    final editingAct = ref.watch(editingActProvider(actId));

    return _EditingActDialogComponent(
      editingAct,
      (pickedStart) => v(
        () => ref.read(editingActProvider(actId).notifier).updatedBy(
              Act.copyWith(
                _act,
                period: DateAndTimePeriod(
                  start: pickedStart,
                  end: editingAct.period.end,
                ),
              ),
            ),
        pickedStart,
      ),
      (pickedEnd) => v(
        () => ref.read(editingActProvider(actId).notifier).updatedBy(
              Act.copyWith(
                _act,
                period: DateAndTimePeriod(
                  start: editingAct.period.start,
                  end: pickedEnd,
                ),
              ),
            ),
        pickedEnd,
      ),
      () => ref.read(deleteAct(_act.identifier)),
      () => v(() async {
        final saved = await save(editingAct);
        ref
            .read(actListProvider(_act.memId).notifier)
            .upsertAll([saved], (tmp, item) => tmp.id == item.id);
      }),
    );
  }
}

class _EditingActDialogComponent extends StatelessWidget {
  final Act _editingAct;
  final Function(DateAndTime? pickedStart) _onStartChanged;
  final Function(DateAndTime? pickedEnd) _onEndChanged;
  final Function() _onDeleteTapped;
  final Function() _onSaveTapped;

  const _EditingActDialogComponent(
    this._editingAct,
    this._onStartChanged,
    this._onEndChanged,
    this._onDeleteTapped,
    this._onSaveTapped,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: DateAndTimePeriodTextFormFields(
        _editingAct.period,
        _onStartChanged,
        _onEndChanged,
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                _onDeleteTapped();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete),
            ),
            IconButton(
              onPressed: () {
                _onSaveTapped();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save_alt),
            ),
          ],
        )
      ],
    );
  }
}
