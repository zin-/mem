import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/app_bar_actions_builder.dart';
import 'package:mem/framework/view/nullable_widget.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/mems/list/filter_action.dart';
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
  final bool _searching;

  const _MemListAppBar(
    this._searching,
  );

  @override
  Widget build(BuildContext context) => v(
        () => SliverAppBar(
          title: NullableWidgetBuilder(
            () => const SearchTextFormField(),
          ).build(),
          floating: true,
          actions: AppBarActionsBuilder([
            SearchAction(context),
            if (!_searching) FilterAction(context),
          ]).build(context),
        ),
        {"_onSearch": _searching},
      );
}
