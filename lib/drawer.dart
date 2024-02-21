import 'package:flutter/material.dart';
import 'package:mem/l10n/app_localizations.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/page.dart';

class ApplicationDrawer extends Drawer {
  ApplicationDrawer(
    AppLocalizations l10n, {
    super.key,
  }) : super(
          child: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.settings),
                title: Text(l10n.settingsPageTitle),
                onTap: () => v(
                  () => Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SettingsPage(),
                    ),
                  ),
                ),
              );
            },
          ),
        );
}
