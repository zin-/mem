import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/app_bar_actions_builder.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/values/durations.dart';

const keyArchiveMem = Key("archive-mem");
const keyUnarchiveMem = Key("unarchive-mem");

class ArchiveMemAction extends AppBarActionBuilder {
  final int _memId;

  ArchiveMemAction(this._memId) : super();

  @override
  Widget popupMenuItemChildBuilder({
    Key Function()? key,
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      Consumer(
        builder: (context, ref, child) {
          final mem = ref.read(memByMemIdProvider(_memId))!;
          if (mem.isArchived) {
            return super.popupMenuItemChildBuilder(
              key: () => keyUnarchiveMem,
              icon: () => const Icon(Icons.unarchive),
              name: () => buildL10n(context).unarchiveAction,
              onPressed: () => () {
                ref.read(unarchiveMem(mem.id));

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
              key: () => keyArchiveMem,
              icon: () => const Icon(Icons.archive),
              name: () => buildL10n(context).archiveFilterTitle,
              onPressed: () => () {
                ref.read(archiveMem(mem.id));

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
        },
      );
}
