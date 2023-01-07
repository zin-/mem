import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/act_counter/select_mem.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/l10n.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_list_item_view.dart';
import 'package:mem/mems/mem_list_page_states.dart';

class ActCounterConfigure extends ConsumerWidget {
  const ActCounterConfigure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(fetchMemList);
    final memList = ref.watch(sortedMemList);

    return _ActCounterConfigureComponent(memList);
  }
}

class _ActCounterConfigureComponent extends StatelessWidget {
  final List<Mem> memList;
  final _scrollController = ScrollController();

  _ActCounterConfigureComponent(this.memList);

  @override
  Widget build(BuildContext context) => t(
        {'memList': memList},
        () {
          return Scaffold(
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  title: Text(L10n().actCounterConfigureTitle()),
                  floating: true,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final mem = memList[index];
                      return MemListItemView(
                        mem,
                        () => {},
                      );
                    },
                    childCount: memList.length,
                  ),
                ),
              ],
            ),
            floatingActionButton: const SelectMem(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      );
}
