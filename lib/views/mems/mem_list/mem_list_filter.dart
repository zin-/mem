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
          final sections = [
            Consumer(
              builder: (context, ref, child) {
                return Column(
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
                );
              },
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
}
