import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/logger/log_service.dart';

const saveIcon = Icons.save_alt;
const deleteIcon = Icons.delete;

class EditingActDialog extends ConsumerWidget {
  final int actId;

  const EditingActDialog(this.actId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actEntity = ref.watch(
      actEntitiesProvider.select(
        (entities) =>
            entities.where((entity) => entity.id == actId).firstOrNull,
      ),
    );

    if (actEntity == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
      return const SizedBox.shrink();
    }

    return _EditingActDialogContent(
      initialAct: actEntity.value,
      onDelete: () => v(() async {
        await ref.read(actEntitiesProvider.notifier).removeAsync([actId]);
      }),
      onSave: (editedAct) => v(() {
        final updatedEntity = actEntity.updatedWith((_) => editedAct);
        ref.read(actEntitiesProvider.notifier).edit(updatedEntity);
      }),
    );
  }
}

class _EditingActDialogContent extends StatefulWidget {
  final Act initialAct;
  final VoidCallback onDelete;
  final Function(Act) onSave;

  const _EditingActDialogContent({
    required this.initialAct,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<_EditingActDialogContent> createState() =>
      _EditingActDialogContentState();
}

class _EditingActDialogContentState extends State<_EditingActDialogContent> {
  late Act _editingAct;

  @override
  void initState() {
    super.initState();
    _editingAct = widget.initialAct;
  }

  void _onPeriodChanged(DateAndTimePeriod? pickedPeriod) {
    setState(() {
      _editingAct = Act.by(
        _editingAct.memId,
        startWhen: pickedPeriod?.start ?? _editingAct.period?.start,
        endWhen: pickedPeriod?.end ?? _editingAct.period?.end,
      );
    });
  }

  void _onSave() {
    widget.onSave(_editingAct);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: widget.onDelete,
              icon: const Icon(deleteIcon),
            ),
            IconButton(
              onPressed: _onSave,
              icon: const Icon(saveIcon),
            ),
          ],
        )
      ],
    );
  }
}
