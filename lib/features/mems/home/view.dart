import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/upcoming_mems.dart';
import 'package:mem/features/mems/list/item/view.dart';

class HomeView extends StatelessWidget {
  final ScrollController _scrollController;

  const HomeView(this._scrollController, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () => ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            UpcomingMemsView(),
          ],
        ),
        {
          '_scrollController': _scrollController,
        },
      );
}

class UpcomingMemsView extends ConsumerWidget {
  const UpcomingMemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mems = ref.watch(upcomingMemsProvider);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mem in mems)
                MemListItemView(
                  mem.toDomain(),
                  key: ValueKey(mem.id),
                ),
            ],
          );
        },
      );
}
