import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';

class RemoveMemAction extends AppBarAction {
  final int? _memId;

  RemoveMemAction(BuildContext context, this._memId)
      : super(
          const Icon(Icons.delete),
          buildL10n(context).removeAction,
          onPressed: _memId == null ? null : () {},
        );

  @override
  Widget buildPopupMenuItemChild(
    BuildContext context, {
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) {
    // TODO: implement buildPopupMenuItemChild
    return Consumer(
      builder: (context, ref, child) {
        final mem = ref.watch(memByMemIdProvider(_memId));
        if (mem is SavedMem) {
          return super.buildPopupMenuItemChild(
            context,
            onPressed: () => () {
              showDialog(
                context: context,
                builder: (context) => _RemoveMemAlertDialog(
                  () => ref.read(removeMem(_memId!)),
                ),
              );
            },
          );
        } else {
          return super.buildPopupMenuItemChild(
            context,
          );
        }
      },
    );
  }
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
