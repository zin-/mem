import 'package:flutter/material.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/mems/list/filter.dart';

class FilterAction extends AppBarActionBuilder {
  FilterAction(BuildContext context)
      : super(
          icon: const Icon(Icons.filter_list),
          name: buildL10n(context).filterAction,
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (context) => const MemListFilter(),
          ),
        );
}
