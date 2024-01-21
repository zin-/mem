import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/nullable_widget_builder.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';

class RemoveMemIconButton extends ConsumerWidget {
  final int? _memId;

  const RemoveMemIconButton(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.watch(memByMemIdProvider((_memId)));

          return mem is SavedMem
              ? _RemoveMemIconButton(
                  () => ref.read(removeMem(_memId!)),
                )
              : nullableWidget;
        },
        {"_memId": _memId},
      );
}

class _RemoveMemIconButton extends StatelessWidget {
  final Future<bool> Function() _removeMem;

  const _RemoveMemIconButton(this._removeMem);

  @override
  Widget build(BuildContext context) => v(
        () => IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => v(
            () => showDialog(
              context: context,
              builder: (context) => _RemoveMemAlertDialog(_removeMem),
            ),
          ),
        ),
      );
}

class _RemoveMemAlertDialog extends StatelessWidget {
  final Future<bool> Function() _removeMem;

  const _RemoveMemAlertDialog(this._removeMem);

  @override
  Widget build(BuildContext context) {
    final l10n = buildL10n(context);

    return AlertDialog(
      content: Text(l10n.removeConfirmation),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () async {
                if (await _removeMem()) {
                  if (context.mounted) {
                    Navigator.of(context)
                      ..pop()
                      ..pop(true);
                  }
                }
              },
              child: Text(l10n.okAction),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelAction),
            ),
          ],
        ),
      ],
    );
  }
}
