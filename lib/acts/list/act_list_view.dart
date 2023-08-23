import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';

import 'item/view.dart';

class ActListView extends ConsumerWidget {
  final int? _memId;

  const ActListView({int? memId, super.key}) : _memId = memId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          List<Mem> mems;
          if (_memId == null) {
            mems = ref.watch(memListProvider);
          } else {
            mems = [
              ref.watch(memListProvider).singleWhereOrNull(
                    (element) => element.id == _memId,
                  )!
            ];
          }
          final actList = ref.watch(actListProvider(_memId)) ?? [];
          return AsyncValueView(
            loadActList(_memId),
            (data) => _ActListViewComponent(
              actList,
              mems,
            ),
          );
        },
        _memId,
      );
}

class _ActListViewComponent extends StatelessWidget {
  final List<Act> _actList;
  final List<Mem> _mems;

  const _ActListViewComponent(this._actList, this._mems);

  @override
  Widget build(BuildContext context) => v(
        () {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(_mems.length == 1 ? _mems.single.name : "Acts"),
                floating: true,
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: _actList.length,
                  // TODO 日付ごとのサブヘッダを追加する
                  (context, index) => ActListItemView(
                    context,
                    _actList[index],
                    mem: _mems.length > 1
                        ? _mems.singleWhereOrNull(
                            (element) => element.id == _actList[index].memId,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          );
        },
        [_actList, _mems],
      );
}
