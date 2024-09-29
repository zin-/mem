import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:mem/l10n/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/router.dart';
import 'package:mem/settings/page.dart';

class _DrawerItem {
  final IconData _icon;
  final String Function(AppLocalizations) _titleBuilder;
  final Function() Function(BuildContext) _onTapBuilder;

  _DrawerItem(this._icon, this._titleBuilder, this._onTapBuilder);
}

class ApplicationDrawer extends StatelessWidget {
  final _itemList = [
    _DrawerItem(
      Icons.settings,
      (AppLocalizations l10n) => l10n.settingsPageTitle,
      (BuildContext context) => () => v(
            () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const SettingsPage(),
              ),
            ),
          ),
    ),
    _DrawerItem(
      Icons.code,
      (AppLocalizations l10n) => l10n.devPageTitle,
      (BuildContext context) => () => v(
// coverage:ignore-start
            () => context.go(devPath),
// coverage:ignore-end
          ),
    ),
  ];

  ApplicationDrawer({super.key});

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return Drawer(
            child: ListView.builder(
              itemCount: _itemList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(_itemList[index]._icon),
                  title: Text(_itemList[index]._titleBuilder(l10n)),
                  onTap: _itemList[index]._onTapBuilder(context),
                );
              },
            ),
          );
        },
        {
          'context': context,
          '_itemList': _itemList,
        },
      );
}
