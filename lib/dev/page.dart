// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:mem/dev/awesome_notifications_wrapper.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/logger/sentry_wrapper.dart';
import 'package:mem/notifications/notification/channel.dart';
import 'package:mem/permissions/permission.dart';
import 'package:mem/permissions/permission_handler_wrapper.dart';
import 'package:mem/values/paths.dart';
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
                      leading: const Icon(Icons.notifications),
                      title: const Text("Awesome notifications"),
                      onPressed: (context) => i(
                        () async {
                          if (await PermissionHandlerWrapper()
                              .grant(Permission.notification)) {
                            await AwesomeNotificationsWrapper(
                              androidDefaultIconPath,
                              l10n,
                              {
                                NotificationChannel(
                                  'awesome-notifications',
                                  'Awesome notifications',
                                  'Try Awesome notifications.',
                                  [],
                                ),
                              },
                            ).show(
                              0,
                              'awesome-notifications',
                              "Hello Awesome notifications!",
                            );
                          }
                        },
                        {
                          'context': context,
                        },
                      ),
                    ),
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
