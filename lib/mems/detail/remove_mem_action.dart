import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';

const keyRemoveMem = Key("remove-mem");

class RemoveMemAction extends AppBarAction {
  final int? _memId;

  RemoveMemAction(BuildContext context, this._memId)
      : super(
          key: keyRemoveMem,
          const Icon(Icons.delete),
          buildL10n(context).removeAction,
          onPressed: _memId == null ? null : () {},
        );

  @override
  Widget popupMenuItemChildBuilder(
    BuildContext context, {
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
    ListTileThemeData? listTileThemeData,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final mem = ref.watch(memByMemIdProvider(_memId));
        if (mem is SavedMem) {
          return super.popupMenuItemChildBuilder(
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
          return super.popupMenuItemChildBuilder(
            context,
          );
        }
      },
    );
  }
}

const keyOk = Key("ok");
const keyCancel = Key("cancel");

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
              key: keyOk,
              onPressed: () async {
                if (await _removeMem()) {
                  if (context.mounted) {
                    Navigator.of(context)
                      ..pop()
                      ..pop()
                      ..pop(true);
                  }
                }
              },
              child: Text(l10n.okAction),
            ),
            ElevatedButton(
              key: keyCancel,
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop(),
              child: Text(l10n.cancelAction),
            ),
          ],
        ),
      ],
    );
  }
}
