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
import 'package:mem/values/colors.dart';
import 'package:mem/values/dimens.dart';

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
        _memId,
      );
}

class _ActListViewComponent extends StatelessWidget {
  final subHeaderTextStyle = const TextStyle(color: secondaryGreyColor);

  final int? _memId;
  final Map<DateTime, List<Act>> _groupedActList;
  final List<SavedMem> _mems;
  final bool _timeView;

  const _ActListViewComponent(
    this._memId,
    this._groupedActList,
    this._mems,
    this._timeView,
  );

  @override
  Widget build(BuildContext context) => v(
        () => CustomScrollView(
          slivers: [
            ActListAppBar(_memId),
            ..._groupedActList.entries.map(
              (e) => SliverStickyHeader(
                header: Container(
                  padding: pagePadding,
                  color: Colors.white,
                  child: ActListSubHeader(e),
                ),
                sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                  childCount: _timeView
                      ? e.value.groupListsBy((element) => element.memId).length
                      : e.value.length,
                  (context, index) {
                    if (_timeView) {
                      final entry = e.value
                          .groupListsBy((element) => element.memId)
                          .entries
                          .toList()[index];

                      return TotalActTimeListItem(
                        entry.value,
                        _mems.length >= 2
                            ? _mems.singleWhereOrNull(
                                (element) => element.id == entry.key)
                            : null,
                      );
                    } else {
                      final act = e.value.toList()[index];
                      if (act is SavedAct) {
                        return ActListItemView(
                          context,
                          act,
                          mem: _mems.length >= 2
                              ? _mems.singleWhereOrNull(
                                  (element) => element.id == act.memId,
                                )
                              : null,
                        );
                      } else {
                        return null;
                      }
                    }
                  },
                )),
              ),
            ),
          ],
        ),
        [_memId, _groupedActList, _mems, _timeView],
      );
}
