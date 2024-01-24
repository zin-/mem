import 'package:flutter/material.dart';
import 'package:mem/acts/list/page.dart';
import 'package:mem/components/app_bar_actions_builder.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';

class TransitActListAction extends AppBarAction {
  TransitActListAction(BuildContext context, int? memId)
      : super(
          const Icon(Icons.play_arrow),
          buildL10n(context).actListDestinationLabel,
          onPressed: memId == null
              ? null
              : () => v(
                    () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ActListPage(memId),
                      ),
                    ),
                  ),
        );
}
