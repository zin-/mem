import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/counter/select_mem_fab.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/mems/list/view.dart';
import 'package:mem/logger/log_service.dart';

import 'single_selectable_mem_list_item.dart';

class ActCounterConfigure extends ConsumerWidget {
  const ActCounterConfigure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const _ActCounterConfigureComponent();
}

class _ActCounterConfigureComponent extends StatelessWidget {
  const _ActCounterConfigureComponent();

  @override
  Widget build(BuildContext context) => i(
        () {
          final l10n = buildL10n(context);

          return Scaffold(
            body: MemListView(
              SliverAppBar(
                title: Text(l10n.actCounterConfigureTitle),
              ),
              (memId) => SingleSelectableMemListItem(memId),
            ),
            floatingActionButton: const SelectMemFab(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      );
}
