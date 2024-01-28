import 'package:flutter/material.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/components/mem/list/filter.dart';

class FilterAction extends AppBarAction {
  FilterAction(BuildContext context)
      : super(
          const Icon(Icons.filter_list),
          buildL10n(context).filter_action,
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (context) => const MemListFilter(),
          ),
        );
}
