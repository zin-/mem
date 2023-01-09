import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_list_item_view.dart';
import 'package:mem/mems/mem_list_page_states.dart';

class MemListView extends ConsumerWidget {
  final String _appBarTitle;

  const MemListView(this._appBarTitle, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MemListViewComponent(_appBarTitle, ref.watch(sortedMemList));
  }
}

class _MemListViewComponent extends StatelessWidget {
  final String _appBarTitle;
  final List<Mem> _memList;

  const _MemListViewComponent(this._appBarTitle, this._memList);

  @override
  Widget build(BuildContext context) => v(
        {'_memList': _memList},
        () {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(_appBarTitle),
                floating: true,
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final mem = _memList[index];
                    return MemListItemView(
                      mem,
                      () => {},
                    );
                  },
                  childCount: _memList.length,
                ),
              ),
            ],
          );
        },
      );
}
