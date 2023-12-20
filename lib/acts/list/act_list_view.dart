import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/list/app_bar.dart';
import 'package:mem/acts/list/states.dart';
import 'package:mem/acts/list/sub_header.dart';
import 'package:mem/acts/list/total_act_time_item.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';

import 'item/view.dart';

class ActListView extends ConsumerWidget {
  final int? _memId;

  const ActListView(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => AsyncValueView(
          loadActList(_memId),
          (data) => _ActListViewComponent(
            _memId,
            (ref.watch(actListProvider(_memId)) ?? []).groupListsBy((element) {
              final dateAndTime = element.period.start!.dateTime;

              return DateTime(
                dateAndTime.year,
                dateAndTime.month,
                dateAndTime.day,
              );
            }),
            (_memId == null
                ? ref.watch(memListProvider)
                : [
                    ref.watch(memListProvider).singleWhereOrNull(
                          (element) => element.id == _memId,
                        )!
                  ]),
            ref.watch(timeViewProvider),
          ),
        ),
        {"_memId": _memId},
      );
}

class _ActListViewComponent extends StatelessWidget {
  final int? _memId;
  final Map<DateTime, List<Act>> _groupedActListByDate;
  final List<SavedMem> _memList;
  final bool _timeView;

  const _ActListViewComponent(
    this._memId,
    this._groupedActListByDate,
    this._memList,
    this._timeView,
  );

  @override
  Widget build(BuildContext context) => v(
        () => CustomScrollView(
          slivers: [
            ActListAppBar(_memId),
            ..._groupedActListByDate.entries.map(
              (e) => SliverStickyHeader(
                header: ActListSubHeader(e),
                sliver: SliverList(
                  delegate: _timeView
                      ? _SummaryActListItem(
                          e.value.groupListsBy((act) => act.memId),
                          _memList,
                        )
                      : _SimpleActListItem(e.value, _memList),
                ),
              ),
            ),
          ],
        ),
        {
          "_memId": _memId,
          "_groupedActList": _groupedActListByDate,
          "_mems": _memList,
          "_timeView": _timeView,
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
              memList.length >= 2
                  ? memList
                      .singleWhereOrNull((element) => element.id == entry.key)
                  : null,
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
                context,
                act,
                mem: memList.length >= 2
                    ? memList.singleWhereOrNull(
                        (element) => element.id == act.memId,
                      )
                    : null,
              );
            } else {
              return null;
            }
          },
        );
}
