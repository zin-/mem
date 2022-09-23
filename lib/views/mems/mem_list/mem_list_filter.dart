import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/mems/mem_list/mem_list_page_states.dart';
import 'package:settings_ui/settings_ui.dart';

const height = 250.0;

class MemListFilter extends StatelessWidget {
  const MemListFilter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () => Consumer(
          builder: (context, ref, child) => SettingsList(
            sections: [
              SettingsSection(
                title: Text(L10n().archiveFilterTitle()),
                tiles: [
                  SettingsTile.switchTile(
                    leading: const Icon(Icons.unarchive),
                    title: Text(L10n().showNotArchivedLabel()),
                    initialValue: ref.watch(showNotArchivedProvider),
                    onToggle: (value) => ref
                        .watch(showNotArchivedProvider.notifier)
                        .updatedBy(value),
                  ),
                  SettingsTile.switchTile(
                    leading: const Icon(Icons.archive),
                    title: Text(L10n().showArchivedLabel()),
                    initialValue: ref.watch(showArchivedProvider),
                    onToggle: (value) => ref
                        .watch(showArchivedProvider.notifier)
                        .updatedBy(value),
                  ),
                ],
              ),
              // SettingsSection(
              //   title: Text(L10n().doneFilterTitle()),
              //   tiles: [
              //     SettingsTile.switchTile(
              //       leading: const Icon(Icons.check_box_outline_blank),
              //       title: Text(L10n().showNotDoneLabel()),
              //       initialValue: ref.watch(showNotDoneProvider),
              //       onToggle: (value) => ref
              //           .watch(showNotDoneProvider.notifier)
              //           .updatedBy(value),
              //     ),
              //     SettingsTile.switchTile(
              //       leading: const Icon(Icons.check_box_outlined),
              //       title: Text(L10n().showDoneLabel()),
              //       initialValue: ref.watch(showDoneProvider),
              //       onToggle: (value) =>
              //           ref.watch(showDoneProvider.notifier).updatedBy(value),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      );
}
