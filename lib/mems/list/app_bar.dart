import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/mem/list/filter.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/states.dart';

class MemListAppBar extends ConsumerWidget {
  const MemListAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _MemListAppBar(
      ref.watch(onSearchProvider),
      ref.read(onSearchProvider.notifier).updatedBy,
      ref.watch(searchTextProvider.notifier).updatedBy,
    );
  }
}

class _MemListAppBar extends StatelessWidget {
  final bool _onSearch;
  final void Function(bool value) _changeOnSearch;

  final void Function(String value) _onSearchTextChanged;

  const _MemListAppBar(
    this._onSearch,
    this._changeOnSearch,
    this._onSearchTextChanged,
  );

  @override
  Widget build(BuildContext context) => v(
        () => SliverAppBar(
          title: _onSearch
              ? TextFormField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search),
                  ),
                  onChanged: _onSearchTextChanged,
                )
              : null,
          floating: true,
          actions: [
            Row(
              children: [
                _onSearch
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _onSearchTextChanged("");
                          _changeOnSearch(false);
                        },
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
          ],
        ),
        {"_onSearch": _onSearch},
      );
}
