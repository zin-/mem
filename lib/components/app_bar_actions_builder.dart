import 'package:flutter/material.dart';
import 'package:mem/logger/log_service.dart';

class AppBarActionsBuilder {
  /// [https://m3.material.io/components/top-app-bar/guidelines#b1b64842-7d88-4c3f-8ffb-4183fe648c9e]
  final _maxShowCount = 3;
  final _popupMenuItemPadding = EdgeInsets.zero;
  final _popupMenuItemHeight = 48.0;

  final List<AppBarActionBuilder> _actions;

  AppBarActionsBuilder(this._actions);

  List<Widget> build(BuildContext context) => v(
        () => (_actions.length > _maxShowCount
                ? [
                    ..._actions
                        .sublist(0, _maxShowCount - 1)
                        .map((e) => e.iconButtonBuilder()),
                    PopupMenuButton(
                      itemBuilder: (context) {
                        return _actions.sublist(_maxShowCount - 1).map(
                          (e) {
                            return PopupMenuItem(
                              padding: _popupMenuItemPadding,
                              child: SizedBox(
                                height: _popupMenuItemHeight,
                                child: ListTileTheme(
                                  data: _createListTileTheme(context),
                                  child: e.popupMenuItemChildBuilder(),
                                ),
                              ),
                            );
                          },
                        ).toList();
                      },
                    ),
                  ]
                : _actions.map((e) => e.iconButtonBuilder()))
            .toList(growable: false),
      );

  ListTileThemeData _createListTileTheme(BuildContext context) =>
      ListTileTheme.of(context).copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
        visualDensity:
            ListTileTheme.of(context).visualDensity?.copyWith(horizontal: 0.0),
      );
}

abstract class AppBarActionBuilder {
  final Key? _key;
  final Icon? _icon;
  final String? _name;
  final VoidCallback? _onPressed;

  AppBarActionBuilder({
    Key? key,
    Icon? icon,
    String? name,
    VoidCallback? onPressed,
  })  : _onPressed = onPressed,
        _name = name,
        _icon = icon,
        _key = key;

  Widget iconButtonBuilder({
    Key Function()? key,
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      v(
        () => IconButton(
          key: key == null ? _key : key(),
          onPressed: onPressed == null ? _onPressed : onPressed(),
          tooltip: name == null ? _name : name(),
          icon: icon == null ? _icon! : icon(),
        ),
        {
          "key": key?.call(),
          "icon": icon?.call(),
          "name": name?.call(),
          "onPressed": onPressed?.call(),
        },
      );

  Widget popupMenuItemChildBuilder({
    Key Function()? key,
    Icon Function()? icon,
    String Function()? name,
    VoidCallback Function()? onPressed,
  }) =>
      v(
        () {
          final resolvedName = name == null ? _name : name();

          return ListTile(
            key: key == null ? _key : key(),
            leading: icon == null ? _icon : icon(),
            title: resolvedName == null ? null : Text(resolvedName),
            onTap: onPressed == null ? _onPressed : onPressed(),
            enabled: onPressed == null ? _onPressed != null : true,
          );
        },
        {
          "key": key?.call(),
          "icon": icon?.call(),
          "name": name?.call(),
          "onPressed": onPressed?.call(),
        },
      );
}
