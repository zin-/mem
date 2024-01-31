import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

/// [https://m3.material.io/components/top-app-bar/guidelines#b1b64842-7d88-4c3f-8ffb-4183fe648c9e]
const _maxShowCount = 3;

class AppBarActionsBuilder {
  final List<AppBarAction> actions;

  AppBarActionsBuilder(this.actions);

  List<Widget> build(BuildContext context) => v(
        () {
          return (actions.length > _maxShowCount
                  ? [
                      ...actions
                          .sublist(0, _maxShowCount - 1)
                          .map((e) => e.iconButtonBuilder()),
                      PopupMenuButton(
                        itemBuilder: (context) {
                          return actions.sublist(_maxShowCount - 1).map(
                            (e) {
                              return PopupMenuItem(
                                // childには基本ListTileを用いるため、zeroを指定し、ListTile側でUIを調整する
                                padding: EdgeInsets.zero,
                                child: SizedBox(
                                  height: 48.0,
                                  child: ListTileTheme(
                                    data: ListTileTheme.of(context).copyWith(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                      ),
                                      minLeadingWidth: 24,
                                      horizontalTitleGap: 12,
                                      visualDensity: ListTileTheme.of(context)
                                          .visualDensity
                                          ?.copyWith(horizontal: 0.0),
                                    ),
                                    child: e.popupMenuItemChildBuilder(context),
                                  ),
                                ),
                              );
                            },
                          ).toList();
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
          key: key,
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

  // MenuItemChildは基本的にはListTileだが、Consumerの利用が必要な場合があるためWidgetとしている
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
          return ListTile(
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
          );
        },
      );
}
