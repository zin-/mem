import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

/// [https://m3.material.io/components/top-app-bar/guidelines#b1b64842-7d88-4c3f-8ffb-4183fe648c9e]
const maxShowCount = 3;

class AppBarActionsBuilderV2 {
  final List<AppBarAction> actions;

  AppBarActionsBuilderV2(this.actions);

  List<Widget>? build() => v(
        () {
          // TODO refactor
          if (actions.length > maxShowCount) {
            return actions
                .sublist(0, maxShowCount - 1)
                .map((e) => e.buildIconButton())
                .toList()
              ..add(
                PopupMenuButton(
                  itemBuilder: (context) => actions
                      .sublist(maxShowCount - 1)
                      .map((e) => e.buildPopupMenuItem())
                      .toList(),
                ),
              )
              ..toList(growable: false);
          } else {
            return actions
                .map((e) => e.buildIconButton())
                .toList(growable: false);
          }
        },
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

  // TODO rename
  //  この段階では表示されることが確定していないため、buildとは呼べない
  PopupMenuItem buildPopupMenuItem({
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      v(
        () =>
            // FIXME なんかおかしい気がする
            //  他のrefactoringで拾えそう？
            PopupMenuItem(
          onTap: onPressed == null ? this.onPressed : onPressed(),
          enabled: onPressed == null ? this.onPressed != null : true,
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
        ),
        {
          "icon": icon,
          "name": name,
          "onPressed": onPressed,
        },
      );
}
