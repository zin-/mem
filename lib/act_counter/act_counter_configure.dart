import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/act_counter/select_mem_fab.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/component/view/mem_list/view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_list_view_state.dart';

class ActCounterConfigure extends ConsumerWidget {
  const ActCounterConfigure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future(() {
      ref
          .read(memListViewModeProvider.notifier)
          .updatedBy(MemListViewMode.singleSelection);
    });

    return const _ActCounterConfigureComponent();
  }
}

class _ActCounterConfigureComponent extends StatelessWidget {
  const _ActCounterConfigureComponent();

  @override
  Widget build(BuildContext context) => i(
        () {
          return Scaffold(
            body: MemListView(L10n().actCounterConfigureTitle()),
            floatingActionButton: const SelectMemFab(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      );
}
