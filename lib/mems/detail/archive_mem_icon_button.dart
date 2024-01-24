import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/mems/detail/actions.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/values/durations.dart';

class ArchiveMemAction extends AppBarAction {
  final int? _memId;

  ArchiveMemAction(BuildContext context, this._memId)
      : super(
          const Icon(Icons.archive),
          buildL10n(context).archiveFilterTitle,
          onPressed: _memId == null ? null : () {},
        );

  @override
  PopupMenuItem buildPopupMenuItem({
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) {
    // TODO: refactor
    return PopupMenuItem(
      onTap: onPressed == null ? this.onPressed : onPressed(),
      enabled: onPressed == null ? this.onPressed != null : true,
      child: Consumer(
        builder: (context, ref, child) {
          final mem = ref.watch(memByMemIdProvider(_memId));
          if (mem is SavedMem) {
            if (mem.isArchived) {
              return ListTile(
                leading: const Icon(Icons.unarchive),
                title: Text(buildL10n(context).unarchive_action),
                onTap: () {
                  ref.read(unarchiveMem(_memId!));

                  Navigator.of(context).pop(null);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(buildL10n(context).unarchiveMemSuccessMessage(
                        mem.name,
                      )),
                      duration: defaultDismissDuration,
                      dismissDirection: DismissDirection.horizontal,
                    ),
                  );
                },
              );
            } else {
              return ListTile(
                leading: const Icon(Icons.archive),
                title: Text(buildL10n(context).archiveFilterTitle),
                onTap: () {
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
            return ListTile(
              leading: icon == null ? this.icon : icon(),
              title: Text(name == null ? this.name : name()),
              enabled: onPressed == null ? this.onPressed != null : true,
            );
          }
        },
      ),
    );
  }
}
