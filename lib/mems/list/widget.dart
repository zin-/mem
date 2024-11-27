import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/async_value_view.dart';
import 'package:mem/mems/list/actions.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/app_bar.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/transitions.dart';

import 'item/view.dart';

class MemListWidget extends ConsumerWidget {
  final ScrollController _scrollController;

  const MemListWidget(this._scrollController, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => AsyncValueView(
          loadMemList,
          (loaded) => _render(
            _scrollController,
            ref.watch(memListProvider),
            (memId) => showMemDetailPage(context, ref, memId),
          ),
        ),
      );
}

Widget _render(
  ScrollController scrollController,
  List<SavedMemEntity> memList,
  void Function(int memId) onItemTapped,
) =>
    v(
      () => CustomScrollView(
        controller: scrollController,
        slivers: [
          const MemListAppBar(),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => MemListItemView(
                memList[index].id,
                onItemTapped,
              ),
              childCount: memList.length,
            ),
          ),
        ],
      ),
      {
        'scrollController': scrollController,
        'memList': memList,
        'onItemTapped': onItemTapped,
      },
    );
