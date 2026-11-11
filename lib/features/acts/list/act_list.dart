import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/widgets/infinite_scroll.dart';

import 'act_list_group.dart';
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
          final memId = widget.memId;
          final listed = memId == null ? ref.watch(memListProvider) : null;
          final focused =
              memId == null ? null : ref.watch(memByMemIdProvider(memId));
          final targets = [
            if (listed != null)
              for (final mem in listed)
                if (mem.target != null) mem.target!,
            if (focused?.target != null) focused!.target!,
          ];

          return _ActList(
            memId,
            ref.watch(dateViewProvider),
            ref.watch(timeViewProvider),
            ref.watch(preferenceProvider(startOfDayKey)),
            ref.watch(actListProvider(memId)),
            listed?.map((e) => e.toDomain()).toList() ?? const [],
            targets,
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
  final Period _groupUnit;
  final bool _isTimeView;
  final TimeOfDay _startOfDay;
  final List<SavedActEntityV1> _actList;
  final List<Mem> _memList;
  final List<Target> _targetList;
  final ScrollController? _scrollController;

  const _ActList(
    this._memId,
    this._groupUnit,
    this._isTimeView,
    this._startOfDay,
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
            ..._groupedActs().entries.map(
                  (e) => SliverStickyHeader(
                    header: ActListSubHeader(
                      e.key,
                      e.value.map((act) => act.value).toList(),
                    ),
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
          '_groupUnit': _groupUnit,
          '_isTimeView': _isTimeView,
          '_startOfDay': _startOfDay,
          '_actList': _actList,
          '_memList': _memList,
          '_targetList': _targetList,
        },
      );

  Map<ActListGroup, List<SavedActEntityV1>> _groupedActs() {
    final groups = <ActListGroup, List<SavedActEntityV1>>{};
    for (final entity in _actList) {
      final period = entity.value.period;
      if (period == null) continue;
      final group = ActListGroup.of(
        unit: _groupUnit,
        at: period.start!,
        startOfDay: _startOfDay,
      );
      if (group == null) continue;
      (groups[group] ??= []).add(entity);
    }
    return groups;
  }
}
