import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/async_value_view.dart';
import 'package:mem/settings/notify_after_inactivity.dart';
import 'package:settings_ui/settings_ui.dart';

import 'package:mem/l10n/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification_client.dart';
import 'package:mem/values/constants.dart';

import 'backup_section.dart';
import 'preference/keys.dart';
import 'states.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => i(
        () {
          return AsyncValueView(
            preferencesProvider,
            (loaded) {
              return _SettingsPage(
                startOfDay: loaded[startOfDayKey] ?? defaultStartOfDay,
                onStartOfDayChanged: (TimeOfDay? picked) => v(
                  () async => await ref
                      .read(preferencesProvider.notifier)
                      .replace(startOfDayKey, picked),
                  {
                    'picked': picked,
                  },
                ),
              );
            },
          );
        },
      );
}

class _SettingsPage extends StatelessWidget {
  final TimeOfDay _startOfDay;
  final void Function(TimeOfDay? picked) _onStartOfDayChanged;

  const _SettingsPage({
    required TimeOfDay startOfDay,
    required onStartOfDayChanged,
  })  : _startOfDay = startOfDay,
        _onStartOfDayChanged = onStartOfDayChanged;

  @override
  Widget build(BuildContext context) => v(
        () {
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
                      _buildStartOfDay(
                        context,
                        l10n.startOfDayLabel,
                        _startOfDay,
                        _onStartOfDayChanged,
                      ),
                      buildNotifyAfterInactivity(context),
                      _buildResetNotification(l10n.resetNotificationLabel),
                    ],
                  ),
                  buildBackupSection(context),
                ],
              ),
            ),
          );
        },
        {"_startOfDay": _startOfDay},
      );
}

SettingsTile _buildStartOfDay(
  BuildContext context,
  String title,
  TimeOfDay startOfDay,
  void Function(TimeOfDay? changed) onChanged,
) =>
    SettingsTile.navigation(
      leading: const Icon(Icons.start),
      title: Text(title),
      onPressed: (context) => v(
        () async => onChanged(
          (await showTimePicker(
            context: context,
            initialTime: startOfDay,
          )),
        ),
      ),
      value: Text(startOfDay.format(context)),
    );

SettingsTile _buildResetNotification(
  String title,
) =>
    SettingsTile.navigation(
      leading: const Icon(Icons.notifications),
      title: Text(title),
      onPressed: (context) => v(
        () {
          NotificationClient(context).resetAll().whenComplete(
                () => v(
                  () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          buildL10n(context).completeResetNotification,
                        ),
                      ),
                    );
                  },
                ),
              );

          showGeneralDialog(
            context: context,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
