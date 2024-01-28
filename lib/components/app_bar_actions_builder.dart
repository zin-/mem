import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

/// [https://m3.material.io/components/top-app-bar/guidelines#b1b64842-7d88-4c3f-8ffb-4183fe648c9e]
const maxShowCount = 3;

class AppBarActions {
  final List<AppBarAction> actions;

  AppBarActions(this.actions);

  List<Widget> build(BuildContext context) => v(
        () {
          return (actions.length > maxShowCount
                  ? [
                      ...actions
                          .sublist(0, maxShowCount - 1)
                          .map((e) => e.iconButtonBuilder()),
                      PopupMenuButton(
                        itemBuilder: (context) {
                          return actions
                              .sublist(maxShowCount - 1)
                              .map((e) => e._popupMenuItemBuilder(context))
                              .toList();
                        },
                      ),
                    ]
                  : actions.map((e) => e.iconButtonBuilder()))
              .toList(growable: false);
        },
      );
}

abstract class AppBarAction {
  final Icon icon;
  final String name;
  final VoidCallback? onPressed;
  final Key? key;

  AppBarAction(
    this.icon,
    this.name, {
    this.onPressed,
    this.key,
  });

  Widget iconButtonBuilder({
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

  Widget popupMenuItemChildBuilder(
    // FIXME BuildContextを削除する
    //  できればここでは使いたくない
    BuildContext context, {
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      v(
        () {
          return ListTileTheme(
            data: _createListTileThemeData(context),
            child: ListTile(
              key: key,
              leading: icon == null ? this.icon : icon(),
              title: Text(name == null ? this.name : name()),
              onTap: () => v(
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
  PopupMenuItem _popupMenuItemBuilder(
    BuildContext context, {
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      v(
        () => PopupMenuItem(
          padding: EdgeInsets.zero,
          enabled: onPressed == null ? this.onPressed != null : true,
          child: popupMenuItemChildBuilder(
            context,
            icon: icon,
            name: name,
            onPressed: onPressed,
          ),
        ),
        {
          "icon": icon,
          "name": name,
          "onPressed": onPressed,
        },
      );

  ListTileThemeData _createListTileThemeData(BuildContext context) => v(
        () => ListTileTheme.of(context).copyWith(
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
      );
}
