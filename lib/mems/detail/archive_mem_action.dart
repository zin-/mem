import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/values/durations.dart';

class ArchiveMemAction extends AppBarActionBuilder {
  final int? _memId;

  ArchiveMemAction(
    BuildContext context,
    this._memId,
    bool memIsSaved,
  ) : super(
          icon: const Icon(Icons.archive),
          onPressed: memIsSaved
              ? () {}
              : _memId == null
                  ? null
                  : () {},
        );

  @override
  Widget popupMenuItemChildBuilder({
    Key Function()? key,
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final mem = ref.watch(editingMemByMemIdProvider(_memId));
        if (mem is SavedMem) {
          if (mem.isArchived) {
            return super.popupMenuItemChildBuilder(
              icon: () => const Icon(Icons.unarchive),
              name: () => buildL10n(context).unarchive_action,
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
        } else {
          return super.popupMenuItemChildBuilder();
        }
      },
    );
  }
}
