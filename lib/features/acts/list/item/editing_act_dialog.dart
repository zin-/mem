import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/logger/log_service.dart';

class EditingActDialog extends ConsumerWidget {
  final int _actId;

  const EditingActDialog(this._actId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editingActEntity = ref.watch(
      actEntitiesProvider.select(
        (e) => e.where((e) => e.id == _actId).firstOrNull,
      ),
    );

    if (editingActEntity == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
      return const SizedBox.shrink();
    }

    return _EditingActDialogStateful(
      initialAct: editingActEntity.value,
      onDelete: () => v(() async {
        await ref.read(actEntitiesProvider.notifier).removeAsync([_actId]);
      }),
      onSave: (editedAct) => v(() {
        final updatedEntity = editingActEntity.updatedWith(
          (v) => editedAct,
        );
        ref.read(actEntitiesProvider.notifier).edit(updatedEntity);
      }),
    );
  }
}

class _EditingActDialogStateful extends StatefulWidget {
  final Act initialAct;
  final VoidCallback onDelete;
  final Function(Act) onSave;

  const _EditingActDialogStateful({
    required this.initialAct,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<_EditingActDialogStateful> createState() =>
      _EditingActDialogStatefulState();
}

class _EditingActDialogStatefulState extends State<_EditingActDialogStateful> {
  late Act _editingAct;

  @override
  void initState() {
    super.initState();
    _editingAct = widget.initialAct;
  }

  @override
  Widget build(BuildContext context) {
    return _EditingActDialogComponent(
      _editingAct,
      (pickedPeriod) => v(
        () {
          setState(() {
            _editingAct = Act.by(
              _editingAct.memId,
              startWhen: pickedPeriod == null
                  ? _editingAct.period?.start
                  : pickedPeriod.start!,
              endWhen: pickedPeriod == null
                  ? _editingAct.period?.end
                  : pickedPeriod.end,
            );
          });
        },
        pickedPeriod,
      ),
      widget.onDelete,
      () => v(() => widget.onSave(_editingAct)),
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
                    onPressed: () async {
                      await _onDeleteTapped();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
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
        {
          '_editingAct': _editingAct,
        },
      );
}
