import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/act_counter/select_mem_fab.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/mem/list/item/states.dart';
import 'package:mem/components/mem/list/view.dart';
import 'package:mem/logger/log_service.dart';

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
