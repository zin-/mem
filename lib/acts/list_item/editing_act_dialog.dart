import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_actions.dart';
import 'package:mem/acts/act_list_page_states.dart';
import 'package:mem/components/date_and_time/date_and_time_period_view.dart';
import 'package:mem/core/act.dart';
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
      (pickedPeriod) => v(
        () => ref.read(editingActProvider(actId).notifier).updatedBy(
              Act.copyWith(
                _act,
                period: pickedPeriod,
              ),
            ),
        pickedPeriod,
      ),
      () => ref.read(deleteAct(_act.identifier)),
      () => v(() => ref.read(actListProvider(_act.memId).notifier).upsertAll(
            [ref.read(saveAct(_act.identifier))],
            (tmp, item) => tmp.id == item.id,
          )),
    );
  }
}

class _EditingActDialogComponent extends StatelessWidget {
  final Act _editingAct;
  final Function(DateAndTimePeriod? picked) _onPeriodChanged;
  final Function() _onDeleteTapped;
  final Function() _onSaveTapped;

  const _EditingActDialogComponent(
    this._editingAct,
    this._onPeriodChanged,
    this._onDeleteTapped,
    this._onSaveTapped,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          return AlertDialog(
            content: DateAndTimePeriodTextFormFields(
              _editingAct.period,
              _onPeriodChanged,
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
        },
        _editingAct,
      );
}
