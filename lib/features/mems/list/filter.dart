import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/mems/list/filter_value.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/logger/log_service.dart';

const height = 250.0;

class MemListFilter extends StatelessWidget {
  const MemListFilter({super.key});

  @override
  Widget build(BuildContext context) => i(
        () {
          final l10n = buildL10n(context);

          return Consumer(
            builder: (context, ref, child) {
              final filter = ref.watch(memListFilterStateProvider);

              void update(MemListFilterValue value) =>
                  ref.read(memListFilterStateProvider.notifier).updatedBy(value);

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
                          value: filter.showNotArchived,
                          onChanged: (value) => update(
                            filter.copyWith(showNotArchived: value),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.archive),
                        Text(l10n.showArchivedLabel),
                        Switch(
                          value: filter.showArchived,
                          onChanged: (value) => update(
                            filter.copyWith(showArchived: value),
                          ),
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
                          value: filter.showNotDone,
                          onChanged: (value) => update(
                            filter.copyWith(showNotDone: value),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_box),
                        Text(l10n.showDoneLabel),
                        Switch(
                          value: filter.showDone,
                          onChanged: (value) => update(
                            filter.copyWith(showDone: value),
                          ),
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
