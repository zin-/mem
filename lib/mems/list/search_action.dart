import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/nullable_widget.dart';
import 'package:mem/mems/list/states.dart';

const _searchIcon = Icon(Icons.search);

class SearchAction extends AppBarAction {
  SearchAction(BuildContext context)
      : super(
          _searchIcon,
          buildL10n(context).search_action,
        );

  @override
  Widget iconButtonBuilder({
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      Consumer(
        builder: (context, ref, child) => ref.watch(searchTextProvider) == null
            ? super.iconButtonBuilder(
                onPressed: () => () {
                  ref.read(searchTextProvider.notifier).updatedBy("");
                },
              )
            : super.iconButtonBuilder(
                icon: () => const Icon(Icons.close),
                name: () => buildL10n(context).close_search_action,
                onPressed: () => () {
                  ref.read(searchTextProvider.notifier).updatedBy(null);
                },
              ),
      );
}

class SearchTextFormField extends ConsumerWidget {
  const SearchTextFormField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(searchTextProvider) == null
        ? nullableWidget
        : TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
              icon: _searchIcon,
            ),
            onChanged: ref.read(searchTextProvider.notifier).updatedBy,
          );
  }
}
