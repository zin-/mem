import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem.dart';

import 'app_bar.dart';
import 'item/total_act_time_item.dart';
import 'item/view.dart';
import 'states.dart';
import 'sub_header.dart';

class ActList extends ConsumerWidget {
  final int? _memId;
  final ScrollController? _scrollController;

  const ActList(
    this._memId,
    this._scrollController, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => AsyncValueView(
          loadActList(_memId),
          (loaded) => _ActList(
            _memId,
            ref.watch(dateViewProvider),
            ref.watch(timeViewProvider),
            ref.watch(actListProvider(_memId)) ?? [],
            (_memId == null ? ref.watch(memListProvider) : []),
            _scrollController,
          ),
        ),
        {
          "_memId": _memId,
        },
      );
}

class _ActList extends StatelessWidget {
  final int? _memId;
  final bool _isDateView;
  final bool _isTimeView;
  final List<Act> _actList;
  final List<SavedMem> _memList;
  final ScrollController? _scrollController;

  const _ActList(
    this._memId,
    this._isDateView,
    this._isTimeView,
    this._actList,
    this._memList,
    this._scrollController,
  );

  @override
  Widget build(BuildContext context) => v(
        () => CustomScrollView(
          controller: _scrollController,
          slivers: [
            ActListAppBar(
              _memId,
            ),
            ..._actList
                .groupListsBy(
                  (element) => DateTime(
                    element.period.start!.year,
                    element.period.start!.month,
                    _isDateView ? element.period.start!.day : 1,
                  ),
                )
                .entries
                .map(
                  (e) => SliverStickyHeader(
                    header: ActListSubHeader(e, _isDateView),
                    sliver: SliverList(
                      delegate: _isTimeView
                          ? _SummaryActListItem(
                              e.value.groupListsBy((element) => element.memId),
                              _memList,
                            )
                          : _SimpleActListItem(e.value, _memList),
                    ),
                  ),
                )
          ],
        ),
        {
          "_memId": _memId,
          "_isDateView": _isDateView,
          "_isTimeView": _isTimeView,
          "_actList": _actList,
          "_memList": _memList,
        },
      );
}

class _SummaryActListItem extends SliverChildBuilderDelegate {
  _SummaryActListItem(
    Map<int, List<Act>> groupedActListByMemId,
    List<SavedMem> memList,
  ) : super(
          childCount: groupedActListByMemId.length,
          (context, index) {
            final entry = groupedActListByMemId.entries.toList()[index];

            return TotalActTimeListItem(
              entry.value,
              memList.singleWhereOrNull((element) => element.id == entry.key),
            );
          },
        );
}

class _SimpleActListItem extends SliverChildBuilderDelegate {
  _SimpleActListItem(
    List<Act> actList,
    List<SavedMem> memList,
  ) : super(
          childCount: actList.length,
          (context, index) {
            final act = actList[index];
            if (act is SavedAct) {
              return ActListItemView(
                act,
                memList
                    .singleWhereOrNull((element) => element.id == act.memId)
                    ?.name,
              );
            } else {
              return null;
            }
          },
        );
}
