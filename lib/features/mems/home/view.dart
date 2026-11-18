import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/habitual_mems.dart';
import 'package:mem/features/mems/home/habitual_mems_view.dart';
import 'package:mem/features/mems/home/overdue_mems_view.dart';
import 'package:mem/features/mems/home/upcoming_mems_view.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/values/dimens.dart';

class HomeView extends ConsumerWidget {
  final ScrollController _scrollController;

  const HomeView(this._scrollController, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _HomeView(
          _scrollController,
          () async {
            ref.invalidate(loadMemListProvider);
            await ref.read(loadMemListProvider.future);
            ref.invalidate(listPeriodCountByMemIdProvider);
            ref.invalidate(habitualMemsProvider);
            await Future.wait([
              ref.read(listPeriodCountByMemIdProvider.future),
              ref.read(habitualMemsProvider.future),
            ]);
          },
        ),
        {
          '_scrollController': _scrollController,
        },
      );
}

class _HomeView extends StatelessWidget {
  final ScrollController _scrollController;
  final Future<void> Function() _onRefresh;

  const _HomeView(this._scrollController, this._onRefresh);

  @override
  Widget build(BuildContext context) => v(
        () => RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            controller: _scrollController,
            padding: cardListPadding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              OverdueMemsView(),
              UpcomingMemsView(),
              HabitualMemsView(),
            ],
          ),
        ),
        {
          '_scrollController': _scrollController,
        },
      );
}
