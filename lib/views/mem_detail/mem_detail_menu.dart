import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n.dart';

import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/views/constants.dart';
import 'package:mem/views/mem_detail/mem_detail_states.dart';

enum MenuOption { remove }

class MemDetailMenu extends StatelessWidget {
  final Map<String, dynamic> _memMap;

  const MemDetailMenu(this._memMap, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {},
        () => Consumer(
          builder: (context, ref, child) => Row(
            children: [
              _buildArchiveButton(context, ref),
              _buildMenu(context, ref),
            ],
          ),
        ),
      );

  Widget _buildArchiveButton(BuildContext context, WidgetRef ref) => v(
        {},
        () => IconButton(
          icon: const Icon(Icons.archive),
          color: Colors.white,
          onPressed: () {
            if (Mem.isSavedMap(_memMap)) {
              ref.read(archiveMem(_memMap)).then((archived) {
                Navigator.of(context).pop(archived);
              });
            } else {
              Navigator.of(context).pop(null);
            }
          },
        ),
      );

  Widget _buildMenu(BuildContext context, WidgetRef ref) => v(
        {},
        () => PopupMenuButton(
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
                builder: (context) => _buildRemoveMemAlertDialog(context, ref),
              );
            }
          },
        ),
      );

  AlertDialog _buildRemoveMemAlertDialog(BuildContext context, WidgetRef ref) =>
      v(
        {},
        () => AlertDialog(
          content: Text(L10n().removeConfirmation()),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    if (Mem.isSavedMap(_memMap)) {
                      ref.read(removeMem(_memMap['id'])).then((result) {
                        if (result) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(L10n()
                                  .removeMemSuccessMessage(_memMap['name'])),
                              duration: defaultDismissDuration,
                              dismissDirection: DismissDirection.horizontal,
                            ),
                          );
                        }
                      });
                    }
                    Navigator.of(context)
                      ..pop()
                      ..pop(null);
                  },
                  child: Text(L10n().okAction()),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(L10n().cancelAction()),
                ),
              ],
            ),
          ],
        ),
      );
}
