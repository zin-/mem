import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/acts/act_entity.dart';

import 'actions.dart';
import 'states.dart';

class EditingActDialog extends ConsumerWidget {
  final int _actId;

  const EditingActDialog(this._actId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editingAct = ref.watch(editingActProvider(_actId));

    return _EditingActDialogComponent(
      editingAct,
      (pickedPeriod) => v(
        () => ref.read(editingActProvider(_actId).notifier).updatedBy(
              editingAct.copiedWith(
                period: pickedPeriod == null ? null : () => pickedPeriod,
              ),
            ),
        pickedPeriod,
      ),
      () => v(() => ref.read(deleteAct(_actId))),
      () => v(
          () => ref.read(actListProvider(editingAct.memId).notifier).upsertAll(
                [ref.read(editAct(_actId))],
                (tmp, item) =>
                    tmp is SavedActEntity &&
                    item is SavedActEntity &&
                    tmp.id == item.id,
              )),
    );
  }
}

class _EditingActDialogComponent extends StatelessWidget {
  final SavedActEntity _editingAct;
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
