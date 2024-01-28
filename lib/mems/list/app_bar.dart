import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/components/mem/list/filter.dart';
import 'package:mem/components/nullable_widget.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/search_action.dart';
import 'package:mem/mems/list/states.dart';

class MemListAppBar extends ConsumerWidget {
  const MemListAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MemListAppBar(
      ref.watch(searchTextProvider) != null,
    );
  }
}

class _MemListAppBar extends StatelessWidget {
  final bool _onSearch;

  const _MemListAppBar(
    this._onSearch,
  );

  @override
  Widget build(BuildContext context) => v(
        () => SliverAppBar(
          title: NullableWidgetBuilder(
            () => const SearchTextFormField(),
          ).build(),
          floating: true,
          actions: [
            ...AppBarActions([
              SearchAction(context),
            ]).build(context),
            Row(
              children: [
                if (!_onSearch)
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (context) => const MemListFilter(),
                    ),
                  ),
              ],
            ),
          ],
        ),
        {"_onSearch": _onSearch},
      );
}
