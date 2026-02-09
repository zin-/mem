import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/widgets/infinite_scroll.dart';

import 'app_bar.dart';
import 'item/builder.dart';
import 'states.dart';
import 'sub_header.dart';

class ActList extends ConsumerStatefulWidget {
  final int? memId;
  final ScrollController? scrollController;

  const ActList(
    this.memId,
    this.scrollController, {
    super.key,
  });

  @override
  ConsumerState<ActList> createState() => _ActListState();
}

class _ActListState extends ConsumerState<ActList> {
  InfiniteScrollController? _infiniteScrollController;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _infiniteScrollController = InfiniteScrollController(
        scrollController: widget.scrollController!,
        ref: ref,
        memId: widget.memId,
      );
    }
  }

  @override
  void dispose() {
    _infiniteScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => v(
        () {
          if (widget.memId == null) {
            ref
                .read(targetsProvider.notifier)
                .fetchByMemIds(ref.watch(memListProvider).map((e) => e.id));
          } else {
            ref.read(targetsProvider.notifier).fetchByMemIds([widget.memId!]);
          }

          return _ActList(
            widget.memId,
            ref.watch(dateViewProvider),
            ref.watch(timeViewProvider),
            ref.watch(actListProvider(widget.memId)),
            (widget.memId == null
                ? ref.watch(memListProvider).map((e) => e.toDomain()).toList()
                : []),
            ref.watch(targetsProvider),
            widget.scrollController,
          );
        },
        {
          'memId': widget.memId,
        },
      );
}

class _ActList extends StatelessWidget {
  final int? _memId;
  final bool _isDateView;
  final bool _isTimeView;
  final List<SavedActEntityV1> _actList;
  final List<Mem> _memList;
  final List<SavedTargetEntity> _targetList;
  final ScrollController? _scrollController;

  const _ActList(
    this._memId,
    this._isDateView,
    this._isTimeView,
    this._actList,
    this._memList,
    this._targetList,
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
                          _targetList,
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
          '_targetList': _targetList,
        },
      );
}
