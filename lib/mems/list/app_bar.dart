import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/mem/list/filter.dart';
import 'package:mem/values/colors.dart';

class MemListAppBar extends StatelessWidget {
  const MemListAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = buildL10n(context);

    return SliverAppBar(
      title: Text(l10n.memListPageTitle),
      floating: true,
      actions: [
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
