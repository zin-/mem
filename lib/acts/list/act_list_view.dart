import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/components/date_and_time/date_and_time_view.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
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
            (ref.watch(actListProvider(_memId)) ?? []).groupListsBy((element) {
              final dateAndTime = element.period.start!.dateTime;

              return DateTime(
                dateAndTime.year,
                dateAndTime.month,
                dateAndTime.day,
              );
            }),
            _memId == null
                ? ref.watch(memListProvider)
                : [
                    ref.watch(memListProvider).singleWhereOrNull(
                          (element) => element.id == _memId,
                        )!
                  ],
          ),
        ),
        _memId,
      );
}

class _ActListViewComponent extends StatelessWidget {
  final subHeaderTextStyle = const TextStyle(color: secondaryGreyColor);

  final Map<DateTime, List<Act>> _groupedActList;
  final List<Mem> _mems;

  const _ActListViewComponent(
    this._groupedActList,
    this._mems,
  );

  @override
  Widget build(BuildContext context) => v(
        () => CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(_mems.length == 1 ? _mems.single.name : "Acts"),
              floating: true,
            ),
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
                        e.value.length.toString(),
                        style: subHeaderTextStyle,
                      )
                    ],
                  ),
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: e.value.length,
                    (context, index) {
                      final act = e.value.toList()[index];
                      return ActListItemView(
                        context,
                        act,
                        mem: _mems.length > 1
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
        [_groupedActList, _mems],
      );
}
