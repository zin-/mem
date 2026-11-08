import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/home/upcoming_mems.dart';
import 'package:mem/features/mems/list/item/view.dart';
import 'package:mem/l10n/l10n.dart';

class UpcomingMemsView extends ConsumerWidget {
  final ScrollController _scrollController;

  const UpcomingMemsView(this._scrollController, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mems = ref.watch(upcomingMemsProvider);
          final l10n = buildL10n(context);

          return ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(
                height: 60.0,
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                alignment: Alignment.centerLeft,
                child: Text(l10n.homeUpcomingSubHeader),
              ),
              for (final mem in mems)
                MemListItemView(
                  mem.toDomain(),
                  key: ValueKey(mem.id),
                ),
            ],
          );
        },
        {
          '_scrollController': _scrollController,
        },
      );
}
