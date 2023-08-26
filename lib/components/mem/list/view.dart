import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/transitions.dart';

import 'actions.dart';
import 'item/view.dart';
import 'states.dart';

class MemListView extends ConsumerWidget {
  final Widget _appBar;
  final ScrollController? _scrollController;

  const MemListView(
    this._appBar, {
    ScrollController? scrollController,
    super.key,
  }) : _scrollController = scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView(
        loadMemList,
        (data) => _MemListViewComponent(
          _appBar,
          ref.watch(memListProvider),
          _scrollController,
          (memId) => showMemDetailPage(context, ref, memId),
        ),
      );
}

class _MemListViewComponent extends StatelessWidget {
  final Widget _appBar;
  final List<Mem> _memList;
  final ScrollController? _scrollController;
  final void Function(MemId memId)? _onItemTapped;

  const _MemListViewComponent(
    this._appBar,
    this._memList,
    this._scrollController,
    this._onItemTapped,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _appBar,
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => MemListItemView(
                    _memList[index].id,
                    _onItemTapped,
                  ),
                  childCount: _memList.length,
                ),
              ),
            ],
          );
        },
        {
          '_appBar': _appBar,
          '_memList': _memList,
          '_scrollController': _scrollController,
          '_onItemTapped': _onItemTapped,
        },
      );
}
