import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => d(
        () {
          // TODO: implement build
          final l10n = buildL10n(context);

          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.settingsPageTitle),
            ),
            body: SafeArea(
              child: SettingsList(
                sections: [
                  SettingsSection(
                    tiles: [
                      SettingsTile.navigation(
                        leading: const Icon(Icons.start),
                        title: Text(l10n.start_of_day_label),
                        onPressed: (context) => d(
                          () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            // TODO save to preference
                            debug(picked);
                          },
                        ),
                        value: Text(
                          // TODO load from preference
                          TimeOfDay.now().format(context),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
}
