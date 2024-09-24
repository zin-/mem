import 'package:flutter/material.dart';
import 'package:mem/acts/line_chart/line_chart_page.dart';
import 'package:mem/framework/view/app_bar_actions_builder.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/logger/log_service.dart';

class TransitChartAction extends AppBarActionBuilder {
  TransitChartAction(BuildContext context, int memId)
      : super(
          icon: const Icon(Icons.show_chart),
          name: buildL10n(context).actChartPageTitle,
          onPressed: () => v(
            () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ActLineChartPage(memId),
              ),
            ),
          ),
        );
}
