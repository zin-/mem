import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/mems/list/states.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_entity.dart';

import 'app_bar.dart';
import 'item/builder.dart';
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
        () {
          final scrollController = _scrollController;
          if (scrollController != null && scrollController.hasClients) {
            if (scrollController.position.maxScrollExtent == 0.0 ||
                scrollController.position.pixels >
                    scrollController.position.maxScrollExtent * 0.6) {
              final c = ref.read(currentPage(_memId));

              if (c < ref.read(maxPage(_memId))) {
                Future.microtask(() {
                  if (ref.read(isLoading(_memId))) {
                    ref.watch(isLoading(_memId)); // coverage:ignore-line
                  } else {
                    ref.read(currentPage(_memId).notifier).updatedBy(c + 1);
                    ref.read(isUpdating(_memId).notifier).updatedBy(false);
                  }
                });
              }
            }
          }

          return _ActList(
            _memId,
            ref.watch(dateViewProvider),
            ref.watch(timeViewProvider),
            ref.watch(actListProvider(_memId)),
            (_memId == null ? ref.watch(memListProvider) : []),
            _scrollController,
          );
        },
        {
          '_memId': _memId,
        },
      );
}

class _ActList extends StatelessWidget {
  final int? _memId;
  final bool _isDateView;
  final bool _isTimeView;
  final List<SavedActEntity> _actList;
  final List<SavedMemEntityV2> _memList;
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
                .where(
                  (e) => e.value.period != null,
                )
                .groupListsBy(
                  (element) => DateTime(
                    element.value.period!.start!.year,
                    element.value.period!.start!.month,
                    _isDateView ? element.value.period!.start!.day : 1,
                  ),
                )
                .entries
                .map(
                  (e) => SliverStickyHeader(
                    header: ActListSubHeader(
                        MapEntry(
                          e.key,
                          e.value.map((e) => e.value).toList(),
                        ),
                        _isDateView),
                    sliver: SliverList(
                      delegate: () {
                        final builder = ActListItemBuilder(
                          e,
                          _memList,
                          _isTimeView,
                        );

                        return SliverChildBuilderDelegate(
                          builder.build,
                          childCount: builder.childCount,
                        );
                      }(),
                    ),
                  ),
                )
          ],
        ),
        {
          '_memId': _memId,
          '_isDateView': _isDateView,
          '_isTimeView': _isTimeView,
          '_actList': _actList,
          '_memList': _memList,
        },
      );
}
