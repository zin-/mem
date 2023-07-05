import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_list_page.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/values/durations.dart';

enum MenuOption { remove }

class MemDetailMenu extends ConsumerWidget {
  final int? _memId;

  const MemDetailMenu(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mem = ref.watch(editingMemProvider(_memId));

    return _MemDetailMenuComponent(
      mem,
      () => ref.read(unarchiveMem(_memId!)),
      () => ref.read(archiveMem(_memId!)),
      () => ref.read(removeMem(_memId!)),
    );
  }
}

class _MemDetailMenuComponent extends StatelessWidget {
  final Mem _mem;
  final Future<MemDetail?> Function() _unarchiveMem;
  final Future<MemDetail?> Function() _archiveMem;
  final Future<bool> Function() _removeMem;

  const _MemDetailMenuComponent(
    this._mem,
    this._unarchiveMem,
    this._archiveMem,
    this._removeMem,
  );

  @override
  Widget build(BuildContext context) {
    final menu = <Widget>[];

    if (_mem.isSaved()) {
      menu.add(_showActIconButton(context, _mem.id));

      if (_mem.isArchived()) {
        menu.add(_unarchiveIconButton(context));
      } else {
        menu.add(_archiveIconButton(context));
      }

      menu.add(_menu(context));
    }

    return Row(
      children: menu,
    );
  }

  IconButton _showActIconButton(BuildContext context, int memId) => IconButton(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ActListPage(memId),
            ),
          );
        },
        icon: const Icon(
          Icons.play_arrow,
          color: Colors.white,
        ),
      );

  IconButton _unarchiveIconButton(BuildContext context) => IconButton(
        icon: const Icon(Icons.unarchive),
        color: Colors.white,
        onPressed: () {
          _unarchiveMem();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n().unarchiveMemSuccessMessage(
                _mem.name,
              )),
              duration: defaultDismissDuration,
              dismissDirection: DismissDirection.horizontal,
            ),
          );
        },
      );

  IconButton _archiveIconButton(BuildContext context) => IconButton(
        icon: const Icon(Icons.archive),
        color: Colors.white,
        onPressed: () {
          _archiveMem();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n().archiveMemSuccessMessage(
                _mem.name,
              )),
              duration: defaultDismissDuration,
              dismissDirection: DismissDirection.horizontal,
            ),
          );

          Navigator.of(context).pop(null);
        },
      );

  Widget _menu(BuildContext context) => PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            value: MenuOption.remove,
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.black),
                Text(L10n().removeAction())
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == MenuOption.remove) {
            showDialog(
              context: context,
              builder: (context) => _RemoveMemAlertDialog(_removeMem),
            );
          }
        },
      );
}

class _RemoveMemAlertDialog extends StatelessWidget {
  final Future<bool> Function() _removeMem;

  const _RemoveMemAlertDialog(this._removeMem);

  @override
  Widget build(BuildContext context) => AlertDialog(
        content: Text(L10n().removeConfirmation()),
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
                child: Text(L10n().okAction()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(L10n().cancelAction()),
              ),
            ],
          ),
        ],
      );
}
