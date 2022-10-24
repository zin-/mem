import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n.dart';
import 'package:mem/logger.dart';
import 'package:mem/views/mems/mem_list/mem_list_page_states.dart';

const height = 250.0;

class MemListFilter extends StatelessWidget {
  const MemListFilter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => t(
        {},
        () {
          return Consumer(
            builder: (context, ref, child) {
              final sections = [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(L10n().archiveFilterTitle()),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.unarchive),
                        Text(L10n().showNotArchivedLabel()),
                        Switch(
                          value: ref.watch(showNotArchivedProvider),
                          onChanged: (value) => ref
                              .read(showNotArchivedProvider.notifier)
                              .updatedBy(value),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.archive),
                        Text(L10n().showArchivedLabel()),
                        Switch(
                          value: ref.watch(showArchivedProvider),
                          onChanged: (value) => ref
                              .read(showArchivedProvider.notifier)
                              .updatedBy(value),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(L10n().doneFilterTitle()),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_box_outline_blank),
                        Text(L10n().showNotDoneLabel()),
                        Switch(
                          value: ref.watch(showNotDoneProvider),
                          onChanged: (value) => ref
                              .read(showNotDoneProvider.notifier)
                              .updatedBy(value),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_box),
                        Text(L10n().showDoneLabel()),
                        Switch(
                          value: ref.watch(showDoneProvider),
                          onChanged: (value) => ref
                              .read(showDoneProvider.notifier)
                              .updatedBy(value),
                        ),
                      ],
                    ),
                  ],
                ),
              ];
              return ListView.builder(
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  return sections[index];
                },
              );
            },
          );
        },
      );
}
