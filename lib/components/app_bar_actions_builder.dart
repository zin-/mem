import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

/// [https://m3.material.io/components/top-app-bar/guidelines#b1b64842-7d88-4c3f-8ffb-4183fe648c9e]
const maxShowCount = 3;

class AppBarActions {
  final List<AppBarAction> actions;

  AppBarActions(this.actions);

  List<Widget> build(BuildContext context) => v(
        () => (actions.length > maxShowCount
                ? [
                    ...actions
                        .sublist(0, maxShowCount - 1)
                        .map((e) => e.buildIconButton()),
                    PopupMenuButton(
                      itemBuilder: (context) => actions
                          .sublist(maxShowCount - 1)
                          .map((e) => e.buildPopupMenuItem(context))
                          .toList(),
                    ),
                  ]
                : actions.map((e) => e.buildIconButton()))
            .toList(growable: false),
      );
}

abstract class AppBarAction {
  final Icon icon;
  final String name;
  final VoidCallback? onPressed;

  AppBarAction(
    this.icon,
    this.name, {
    this.onPressed,
  });

  // TODO rename
  //  この段階では表示されることが確定していないため、buildとは呼べない
  Widget buildIconButton({
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      v(
        () => IconButton(
          onPressed: onPressed == null ? this.onPressed : onPressed(),
          tooltip: name == null ? this.name : name(),
          icon: icon == null ? this.icon : icon(),
        ),
        {
          "icon": icon,
          "name": name,
          "onPressed": onPressed,
        },
      );

  Widget buildPopupMenuItemChild(
    BuildContext context, {
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      d(
        () {
          return ListTileTheme(
            data: ListTileTheme.of(context).copyWith(
              contentPadding: EdgeInsets.symmetric(
                horizontal: Theme.of(context).useMaterial3 ? 12.0 : 16.0,
              ),
              minLeadingWidth: 24,
              horizontalTitleGap: Theme.of(context).useMaterial3 ? 12 : 20,
              visualDensity: Theme.of(context)
                  .listTileTheme
                  .visualDensity
                  ?.copyWith(horizontal: 0.0),
            ),
            child: ListTile(
              leading: icon == null ? this.icon : icon(),
              title: Text(name == null ? this.name : name()),
              onTap: () => d(
                () {
                  if (onPressed == null) {
                    this.onPressed?.call();
                  } else {
                    onPressed()();
                  }
                },
              ),
              enabled: onPressed == null ? this.onPressed != null : true,
            ),
          );
        },
      );

  // TODO rename
  //  この段階では表示されることが確定していないため、buildとは呼べない
  PopupMenuItem buildPopupMenuItem(
    BuildContext context, {
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      v(
        () {
          return PopupMenuItem(
            padding: EdgeInsets.zero,
            enabled: onPressed == null ? this.onPressed != null : true,
            child: buildPopupMenuItemChild(
              context,
              icon: icon,
              name: name,
              onPressed: onPressed,
            ),
          );
        },
        {
          "icon": icon,
          "name": name,
          "onPressed": onPressed,
        },
      );
}
