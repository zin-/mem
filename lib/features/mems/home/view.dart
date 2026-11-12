import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/upcoming_mems.dart';
import 'package:mem/features/mems/list/item/view.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/dimens.dart';

class HomeView extends StatelessWidget {
  final ScrollController _scrollController;

  const HomeView(this._scrollController, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () => ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            OverdueMemsView(),
            UpcomingMemsView(),
          ],
        ),
        {
          '_scrollController': _scrollController,
        },
      );
}

class OverdueMemsView extends ConsumerWidget {
  const OverdueMemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _HomeMemsCard(
          ref.watch(overdueMemsProvider),
          color: warningSurfaceOn(Theme.of(context).colorScheme.surface),
        ),
      );
}

class UpcomingMemsView extends ConsumerWidget {
  const UpcomingMemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => _HomeMemsCard(ref.watch(upcomingMemsProvider)),
      );
}

class _HomeMemsCard extends StatelessWidget {
  final List<MemEntity> _mems;
  final Color? _color;

  const _HomeMemsCard(this._mems, {Color? color}) : _color = color;

  @override
  Widget build(BuildContext context) {
    if (_mems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: defaultPadding,
      color: _color,
      clipBehavior: Clip.antiAlias,
      semanticContainer: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final mem in _mems)
            MemListItemView(
              mem.toDomain(),
              key: ValueKey(mem.id),
            ),
        ],
      ),
    );
  }
}
