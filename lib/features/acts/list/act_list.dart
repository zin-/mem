import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/features/targets/target.dart';
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
  final bool _isDateView;
  final bool _isTimeView;
  final TimeOfDay _startOfDay;
  final List<SavedActEntityV1> _actList;
  final List<Mem> _memList;
  final List<Target> _targetList;
  final ScrollController? _scrollController;

  const _ActList(
    this._memId,
    this._isDateView,
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
            ..._actList
                .where(
                  (e) => e.value.period != null,
                )
                .groupListsBy(
                  (element) {
                    final day = element.value.period!.start!.logicalDay(
                      _startOfDay,
                    );
                    return DateTime(
                      day.year,
                      day.month,
                      _isDateView ? day.day : 1,
                    );
                  },
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
                          _isDateView,
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
          '_startOfDay': _startOfDay,
          '_actList': _actList,
          '_memList': _memList,
          '_targetList': _targetList,
        },
      );
}
