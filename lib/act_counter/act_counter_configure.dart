import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/act_counter/select_mem.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_list_page_states.dart';
import 'package:mem/mems/mem_list_view.dart';
import 'package:mem/mems/mem_list_view_state.dart';

class ActCounterConfigure extends ConsumerWidget {
  const ActCounterConfigure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(fetchMemList);
    ref
        .read(memListViewModeProvider.notifier)
        .updatedBy(MemListViewMode.singleSelection);

    return const _ActCounterConfigureComponent();
  }
}

class _ActCounterConfigureComponent extends StatelessWidget {
  const _ActCounterConfigureComponent();

  @override
  Widget build(BuildContext context) => t(
        {},
        () {
          return Scaffold(
            body: MemListView(L10n().actCounterConfigureTitle()),
            // TODO 選択を確定したらHome Widgetに情報を送る
            floatingActionButton: const SelectMem(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      );
}
