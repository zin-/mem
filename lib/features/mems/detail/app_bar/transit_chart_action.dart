import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mem/framework/view/app_bar_actions_builder.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/router.dart';

class TransitChartAction extends AppBarActionBuilder {
  TransitChartAction(BuildContext context, int memId)
      : super(
          icon: const Icon(Icons.show_chart),
          name: buildL10n(context).actChartPageTitle,
          onPressed: () => v(
            () => context.push(buildMemChartPath(memId)),
          ),
        );
}
