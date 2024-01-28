import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/values/durations.dart';

const keyArchiveMem = Key("archive-mem");

class ArchiveMemAction extends AppBarAction {
  final int? _memId;

  ArchiveMemAction(BuildContext context, this._memId)
      : super(
          key: keyArchiveMem,
          const Icon(Icons.archive),
          buildL10n(context).archiveFilterTitle,
          onPressed: _memId == null ? null : () {},
        );

  @override
  Widget popupMenuItemChildBuilder(
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
          if (mem.isArchived) {
            return super.popupMenuItemChildBuilder(
              context,
              icon: () => const Icon(Icons.unarchive),
              name: () => buildL10n(context).unarchive_action,
              onPressed: () => () {
                ref.read(unarchiveMem(_memId!));

                Navigator.of(context).pop(null);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(buildL10n(context).unarchiveMemSuccessMessage(
                      mem.name,
                    )),
                    duration: defaultDismissDuration,
                    dismissDirection: DismissDirection.horizontal,
                  ),
                );
              },
            );
          } else {
            return super.popupMenuItemChildBuilder(
              context,
              icon: () => const Icon(Icons.archive),
              name: () => buildL10n(context).archiveFilterTitle,
              onPressed: () => () {
                ref.read(archiveMem(_memId!));

                Navigator.of(context)
                  ..pop(null)
                  ..pop(null);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      buildL10n(context).archiveMemSuccessMessage(
                        mem.name,
                      ),
                    ),
                    duration: defaultDismissDuration,
                    dismissDirection: DismissDirection.horizontal,
                  ),
                );
              },
            );
          }
        } else {
          return super.popupMenuItemChildBuilder(
            context,
          );
        }
      },
    );
  }
}
