import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem_entity.dart';

import 'actions.dart';
import 'states.dart';

class MemListView extends ConsumerWidget {
  final Widget _appBar;
  final ScrollController? _scrollController;
  final Widget Function(int memId) _itemBuilder;

  const MemListView(
    this._appBar,
    this._itemBuilder, {
    ScrollController? scrollController,
    super.key,
  }) : _scrollController = scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView(
        loadMemList,
        (data) => _MemListViewComponent(
          ref.watch(memListProvider),
          _appBar,
          _itemBuilder,
          _scrollController,
        ),
      );
}

class _MemListViewComponent extends StatelessWidget {
  final List<SavedMemEntity> _memList;
  final Widget _appBar;
  final Widget Function(int memId) _itemBuilder;
  final ScrollController? _scrollController;

  const _MemListViewComponent(
    this._memList,
    this._appBar,
    this._itemBuilder,
    this._scrollController,
  );

  @override
  Widget build(BuildContext context) => v(
        () => CustomScrollView(
          controller: _scrollController,
          slivers: [
            _appBar,
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _itemBuilder(_memList[index].id),
                childCount: _memList.length,
              ),
            ),
          ],
        ),
        {
          '_memList': _memList,
          '_appBar': _appBar,
          '_scrollController': _scrollController,
        },
      );
}
