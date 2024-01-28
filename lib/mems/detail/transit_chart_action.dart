import 'package:flutter/material.dart';
import 'package:mem/acts/line_chart/line_chart_page.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';

class TransitChartAction extends AppBarAction {
  TransitChartAction(BuildContext context, int? memId)
      : super(
          const Icon(Icons.show_chart),
          buildL10n(context).actChartPageTitle,
          onPressed: memId == null
              ? null
              : () => v(
                    () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ActLineChartPage(memId),
                      ),
                    ),
                  ),
        );
}
