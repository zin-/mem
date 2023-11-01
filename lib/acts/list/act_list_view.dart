import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/list/app_bar.dart';
import 'package:mem/acts/list/states.dart';
import 'package:mem/acts/list/total_act_time_item.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/components/date_and_time/date_and_time_view.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/duration.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/dimens.dart';

import 'item/view.dart';

class ActListView extends ConsumerWidget {
  final int? _memId;

  const ActListView({int? memId, super.key}) : _memId = memId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => AsyncValueView(
          loadActList(_memId),
          (data) => _ActListViewComponent(
            _memId,
            (ref.watch(actListProvider(_memId)) ?? [])
                .map((e) => e.toV1())
                .groupListsBy((element) {
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DateAndTimeText(
                        DateAndTime.from(e.key),
                        style: subHeaderTextStyle,
                      ),
                      Text(
                        _timeView
                            ? e.value
                                .fold<Duration>(
                                    Duration.zero,
                                    (previousValue, element) =>
                                        previousValue + element.period.duration)
                                .format()
                            : e.value.length.toString(),
                        style: subHeaderTextStyle,
                      )
                    ],
                  ),
                ),
                sliver: SliverList(
                  delegate: _timeView
                      ? SliverChildBuilderDelegate(
                          childCount: e.value
                              .groupListsBy((element) => element.memId)
                              .length,
                          (context, index) {
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
                          },
                        )
                      : SliverChildBuilderDelegate(
                          childCount: e.value.length,
                          (context, index) {
                            final act = e.value.toList()[index];
                            return ActListItemView(
                              context,
                              act,
                              mem: _mems.length >= 2
                                  ? _mems.singleWhereOrNull(
                                      (element) => element.id == act.memId,
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
        [_memId, _groupedActList, _mems, _timeView],
      );
}
