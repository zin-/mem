import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/logger/log_service.dart';

const height = 250.0;

class MemListFilter extends StatelessWidget {
  const MemListFilter({super.key});

  @override
  Widget build(BuildContext context) => i(
        () {
          final l10n = buildL10n(context);

          return Consumer(
            builder: (context, ref, child) {
              final sections = [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.archiveFilterTitle),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.unarchive),
                        Text(l10n.showNotArchivedLabel),
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
                        Text(l10n.showArchivedLabel),
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
                        Text(l10n.doneFilterTitle),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_box_outline_blank),
                        Text(l10n.showNotDoneLabel),
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
                        Text(l10n.showDoneLabel),
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
