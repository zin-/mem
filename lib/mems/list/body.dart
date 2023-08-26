import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/mem/list/view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/list/actions.dart';
import 'package:mem/components/mem/list/filter.dart';
import 'package:mem/values/colors.dart';

class MemListBody extends ConsumerWidget {
  final ScrollController _scrollController;

  const MemListBody(this._scrollController, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => i(
        () {
          ref.read(fetchActiveActs);

          return _MemListBodyComponent(_scrollController);
        },
      );
}

class _MemListBodyComponent extends StatelessWidget {
  final ScrollController _scrollController;

  const _MemListBodyComponent(this._scrollController);

  @override
  Widget build(BuildContext context) {
    final l10n = buildL10n(context);

    return MemListView(
      l10n.memListPageTitle,
      scrollController: _scrollController,
      appBarActions: [
        IconTheme(
          data: const IconThemeData(color: iconOnPrimaryColor),
          child: Row(
            children: [
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
