import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/components/nullable_widget.dart';
import 'package:mem/mems/list/states.dart';

const _searchIcon = Icon(Icons.search);
const keySearch = Key("search");
const keyCloseSearch = Key("close-search");

class SearchAction extends AppBarActionBuilder {
  SearchAction(BuildContext context) : super(icon: _searchIcon);

  @override
  Widget iconButtonBuilder({
    Key Function()? key,
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      Consumer(
        builder: (context, ref, child) => ref.watch(searchTextProvider) == null
            ? super.iconButtonBuilder(
                key: () => keySearch,
                name: () => buildL10n(context).searchAction,
                onPressed: () => () {
                  ref.read(searchTextProvider.notifier).updatedBy("");
                },
              )
            : super.iconButtonBuilder(
                key: () => keyCloseSearch,
                icon: () => const Icon(Icons.close),
                name: () => buildL10n(context).closeSearchAction,
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
