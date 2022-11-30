import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_list_page.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/gui/constants.dart';
import 'package:mem/mems/mem_detail_states.dart';

enum MenuOption { remove }

class MemDetailMenu extends StatelessWidget {
  final int? _memId;

  const MemDetailMenu(this._memId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => v(
        {'_memId': _memId},
        () => Consumer(builder: (context, ref, child) {
          final mem = ref.watch(memProvider(_memId));

          final menu = <Widget>[];

          if (mem?.isSaved() ?? false) {
            menu.add(_buildShowActPage(context, mem?.id as MemId));
          }

          if (mem?.isArchived() ?? false) {
            menu.add(_buildUnArchiveButton(context));
          } else {
            menu.add(_buildArchiveButton(context));
          }

          menu.add(_buildMenu(context));

          return Row(children: menu);
        }),
      );

  Widget _buildUnArchiveButton(BuildContext context) => v(
        {},
        () => Consumer(
          builder: (context, ref, child) {
            return IconButton(
              icon: const Icon(Icons.unarchive),
              color: Colors.white,
              onPressed: () {
                ref.read(unarchiveMem(_memId)).then(
                  (archived) {
                    if (archived != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(L10n().unarchiveMemSuccessMessage(
                            archived.mem.name,
                          )),
                          duration: defaultDismissDuration,
                          dismissDirection: DismissDirection.horizontal,
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      );

  Widget _buildArchiveButton(BuildContext context) => v(
        {},
        () => Consumer(
          builder: (context, ref, child) {
            return IconButton(
              icon: const Icon(Icons.archive),
              color: Colors.white,
              onPressed: () {
                final scaffoldManager = ScaffoldMessenger.of(context);
                ref.read(archiveMem(_memId)).then(
                  (archivedMemDetail) {
                    if (archivedMemDetail != null) {
                      scaffoldManager.showSnackBar(
                        SnackBar(
                          content: Text(L10n().archiveMemSuccessMessage(
                            archivedMemDetail.mem.name,
                          )),
                          duration: defaultDismissDuration,
                          dismissDirection: DismissDirection.horizontal,
                        ),
                      );
                    }
                  },
                );
                Navigator.of(context).pop(null);
              },
            );
          },
        ),
      );

  Widget _buildShowActPage(BuildContext context, MemId memId) => v(
        {},
        () {
          return IconButton(
            onPressed: () => v({'memId': memId}, () {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ActListPage(memId),
              ));
            }),
            icon: const Icon(
              Icons.play_arrow,
              color: Colors.white,
            ),
          );
        },
      );

  Widget _buildMenu(BuildContext context) => v(
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
                builder: (context) => _buildRemoveMemAlertDialog(context),
              );
            }
          },
        ),
      );

  AlertDialog _buildRemoveMemAlertDialog(BuildContext context) => v(
        {},
        () => AlertDialog(
          content: Text(L10n().removeConfirmation()),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Consumer(
                  builder: (context, ref, child) {
                    final mem = ref.watch(memProvider(_memId));

                    return ElevatedButton(
                      onPressed: () async {
                        if (mem != null) {
                          ref.read(removeMem(mem.id));
                        }
                        Navigator.of(context)
                          ..pop()
                          ..pop(null);
                      },
                      child: Text(L10n().okAction()),
                    );
                  },
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
        ),
      );
}
