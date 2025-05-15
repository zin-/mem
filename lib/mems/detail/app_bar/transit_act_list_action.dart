import 'package:flutter/material.dart';
import 'package:mem/features/acts/list/page.dart';
import 'package:mem/framework/view/app_bar_actions_builder.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/logger/log_service.dart';

class TransitActListAction extends AppBarActionBuilder {
  TransitActListAction(BuildContext context, int memId)
      : super(
          icon: const Icon(Icons.play_arrow),
          name: buildL10n(context).actListDestinationLabel,
          onPressed: () => v(
            () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ActListPage(memId),
              ),
            ),
          ),
        );
}
