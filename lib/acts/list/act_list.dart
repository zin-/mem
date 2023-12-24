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
import 'package:mem/components/l10n.dart';
import 'package:mem/components/mem/list/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/values/constants.dart';

import 'item/view.dart';

class ActList extends ConsumerWidget {
  final int? _memId;

  const ActList(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => AsyncValueView(
          loadActList(_memId),
          (loaded) => _ActList(
            _ActListIF(
              ActListAppBarIF(
                _memId == null
                    ? buildL10n(context).defaultActListPageTitle
                    : ref.read(memProvider(_memId!))?.name ?? somethingWrong,
                (bool changed) =>
                    ref.read(timeViewProvider.notifier).updatedBy(changed),
              ),
              ref.watch(timeViewProvider),
              ref.watch(actListProvider(_memId)) ?? [],
              (_memId == null
                  ? ref.watch(memListProvider)
                  : [
                      ref.watch(memListProvider).singleWhereOrNull(
                            (element) => element.id == _memId,
                          )!
                    ]),
            ),
          ),
        ),
        {"_memId": _memId},
      );
}

class _ActListIF {
  final ActListAppBarIF _actListAppBarIF;
  final bool _isTimeView;
  final List<Act> _actList;
  final List<SavedMem> _memList;

  _ActListIF(
    this._actListAppBarIF,
    this._isTimeView,
    this._actList,
    this._memList,
  );

  Map<String, dynamic> _toMap() => {
        "_actListAppBarIF": _actListAppBarIF,
        "_isTimeView": _isTimeView,
        "_actList": _actList,
        "_memList": _memList,
      };

  @override
  String toString() => _toMap().toString();
}

class _ActList extends StatelessWidget {
  final _ActListIF _actListIF;

  const _ActList(this._actListIF);

  @override
  Widget build(BuildContext context) => v(
        () => CustomScrollView(
          slivers: [
            ActListAppBar(
              _actListIF._actListAppBarIF,
              _actListIF._isTimeView,
            ),
            ..._actListIF._actList
                .groupListsBy(
                  (element) => DateTime(
                    element.period.start!.year,
                    element.period.start!.month,
                  ),
                )
                .entries
                .map(
                  (e) => SliverStickyHeader(
                    header: ActListSubHeader(e),
                    sliver: SliverList(
                      delegate: _actListIF._isTimeView
                          ? _SummaryActListItem(
                              e.value.groupListsBy((element) => element.memId),
                              _actListIF._memList,
                            )
                          : _SimpleActListItem(e.value, _actListIF._memList),
                    ),
                  ),
                )
          ],
        ),
        _actListIF,
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
                act,
                (memList.length >= 2
                        ? memList.singleWhereOrNull(
                            (element) => element.id == act.memId,
                          )
                        : null)
                    ?.name,
              );
            } else {
              return null;
            }
          },
        );
}
