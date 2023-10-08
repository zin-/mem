import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/mem/list/filter.dart';
import 'package:mem/mems/list/app_bar/states.dart';
import 'package:mem/values/colors.dart';

class MemListAppBar extends ConsumerWidget {
  const MemListAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MemListAppBar(
      ref.watch(onSearchProvider),
      ref.read(onSearchProvider.notifier).updatedBy,
      // ref.read(searchTextProvider.notifier).updatedBy,
    );
  }
}

class _MemListAppBar extends StatelessWidget {
  final bool _onSearch;
  final void Function(bool value) _changeOnSearch;

  // final void Function(String value) _onSearchTextChanged;

  const _MemListAppBar(
    this._onSearch,
    this._changeOnSearch,
    // this._onSearchTextChanged,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = buildL10n(context);

    return SliverAppBar(
      title: _onSearch
          ? TextFormField(
              autofocus: true,
              // onChanged: _onSearchTextChanged,
            )
          : Text(l10n.memListPageTitle),
      floating: true,
      actions: [
        IconTheme(
          data: const IconThemeData(color: iconOnPrimaryColor),
          child: Row(
            children: [
              _onSearch
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _changeOnSearch(false),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _changeOnSearch(true),
                    ),
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
        ),
      ],
    );
  }
}
