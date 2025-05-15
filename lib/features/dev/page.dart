// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/logger/sentry_wrapper.dart';
import 'package:settings_ui/settings_ui.dart';

class DevPage extends StatelessWidget {
  const DevPage({super.key});

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);

          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.devPageTitle),
            ),
            body: SettingsList(
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile.navigation(
                      title: const Text('Test send to Sentry'),
                      onPressed: (context) async {
                        await SentryWrapper().captureException(
                          "Test send to Sentry",
                          StackTrace.current,
                        );
                      },
                    )
                  ],
                )
              ],
            ),
          );
        },
      );
}
