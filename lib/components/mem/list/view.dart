import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/body.dart';
import 'package:mem/values/colors.dart';

import 'actions.dart';
import 'item/view.dart';
import 'states.dart';

class MemListView extends ConsumerWidget {
  final String _appBarTitle;
  final ScrollController? _scrollController;
  final List<Widget> _appBarActions;

  MemListView(
    this._appBarTitle, {
    ScrollController? scrollController,
    List<Widget>? appBarActions,
    super.key,
  })  : _scrollController = scrollController,
        _appBarActions = appBarActions ?? [];

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView(
        loadMemList,
        (data) => _MemListViewComponent(
          _appBarTitle,
          ref.watch(memListProvider),
          _scrollController,
          _appBarActions,
          (memId) => showMemDetailPage(context, ref, memId),
        ),
      );
}

class _MemListViewComponent extends StatelessWidget {
  final String _appBarTitle;
  final List<Mem> _memList;
  final ScrollController? _scrollController;
  final List<Widget> _appBarActions;
  final void Function(MemId memId)? _onItemTapped;

  const _MemListViewComponent(
    this._appBarTitle,
    this._memList,
    this._scrollController,
    this._appBarActions,
    this._onItemTapped,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                title: Text(_appBarTitle),
                floating: true,
                actions: [
                  IconTheme(
                    data: const IconThemeData(color: iconOnPrimaryColor),
                    child: Row(
                      children: _appBarActions,
                    ),
                  ),
                ],
              ),
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
          '_appBarTitle': _appBarTitle,
          '_memList': _memList,
          '_scrollController': _scrollController,
          '_appBarActions': _appBarActions,
          '_onItemTapped': _onItemTapped,
        },
      );
}
