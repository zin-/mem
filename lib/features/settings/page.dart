import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/settings/app_version.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/features/settings/habitual_mems_count.dart';
import 'package:mem/features/settings/notify_after_inactivity.dart';
import 'package:mem/features/settings/number_picker_tile.dart';
import 'package:settings_ui/settings_ui.dart';

import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/notifications/notification_client.dart';

import 'backup_section.dart';
import 'preference/keys.dart';
import 'states.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => i(
        () => _SettingsPage(
          ref.watch(preferenceProvider(startOfDayKey)),
          (TimeOfDay? picked) => v(
            () => picked == null
                ? ref.read(preferenceProvider(startOfDayKey).notifier).remove()
                : ref
                    .read(preferenceProvider(startOfDayKey).notifier)
                    .replace(picked),
            {
              'picked': picked,
            },
          ),
          ref.watch(preferenceProvider(notifyAfterInactivity)),
          (picked) => v(
            () => picked == null
                ? ref
                    .read(preferenceProvider(notifyAfterInactivity).notifier)
                    .remove()
                : ref
                    .read(preferenceProvider(notifyAfterInactivity).notifier)
                    .replace(picked),
            {
              'picked': picked,
            },
          ),
          ref.watch(preferenceProvider(habitualMemsCountKey)),
          (picked) => v(
            () => picked == null
                ? ref
                    .read(preferenceProvider(habitualMemsCountKey).notifier)
                    .remove()
                : ref
                    .read(preferenceProvider(habitualMemsCountKey).notifier)
                    .replace(picked),
            {
              'picked': picked,
            },
          ),
          ref.watch(preferenceProvider(habitualMemsTimeRadiusKey)),
          (picked) => v(
            () => picked == null
                ? ref
                    .read(
                        preferenceProvider(habitualMemsTimeRadiusKey).notifier)
                    .remove()
                : ref
                    .read(
                        preferenceProvider(habitualMemsTimeRadiusKey).notifier)
                    .replace(picked),
            {
              'picked': picked,
            },
          ),
          ref.watch(preferenceProvider(habitualMemsLookbackKey)),
          (picked) => v(
            () => picked == null
                ? ref
                    .read(preferenceProvider(habitualMemsLookbackKey).notifier)
                    .remove()
                : ref
                    .read(preferenceProvider(habitualMemsLookbackKey).notifier)
                    .replace(picked),
            {
              'picked': picked,
            },
          ),
          ref.watch(appVersionProvider).value,
        ),
      );
}

class _SettingsPage extends StatelessWidget {
  final TimeOfDay _startOfDay;
  final void Function(TimeOfDay? picked) _onStartOfDayChanged;
  final int? _notifyAfterInactivity;
  final void Function(int? picked) _onNotifyAfterInactivityChanged;
  final int? _habitualMemsCount;
  final void Function(int? picked) _onHabitualMemsCountChanged;
  final int? _habitualMemsTimeRadius;
  final void Function(int? picked) _onHabitualMemsTimeRadiusChanged;
  final int? _habitualMemsLookback;
  final void Function(int? picked) _onHabitualMemsLookbackChanged;
  final AppVersion? _appVersion;

  const _SettingsPage(
    this._startOfDay,
    this._onStartOfDayChanged,
    this._notifyAfterInactivity,
    this._onNotifyAfterInactivityChanged,
    this._habitualMemsCount,
    this._onHabitualMemsCountChanged,
    this._habitualMemsTimeRadius,
    this._onHabitualMemsTimeRadiusChanged,
    this._habitualMemsLookback,
    this._onHabitualMemsLookbackChanged,
    this._appVersion,
  );

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);
          final appVersion = _appVersion;

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
                      buildNotifyAfterInactivity(
                        context,
                        _notifyAfterInactivity,
                        _onNotifyAfterInactivityChanged,
                      ),
                      buildHabitualMemsCount(
                        context,
                        _habitualMemsCount,
                        _onHabitualMemsCountChanged,
                      ),
                      buildNumberPickerTile(
                        context,
                        l10n.habitualMemsTimeRadiusLabel,
                        _habitualMemsTimeRadius,
                        _onHabitualMemsTimeRadiusChanged,
                        min: minHabitualMemsTimeRadius,
                        max: maxHabitualMemsTimeRadius,
                        defaultValue: defaultHabitualMemsTimeRadius,
                        icon: Icons.timelapse,
                      ),
                      buildNumberPickerTile(
                        context,
                        l10n.habitualMemsLookbackLabel,
                        _habitualMemsLookback,
                        _onHabitualMemsLookbackChanged,
                        min: minHabitualMemsLookback,
                        max: maxHabitualMemsLookback,
                        defaultValue: defaultHabitualMemsLookback,
                        icon: Icons.date_range,
                      ),
                      _buildResetNotification(l10n.resetNotificationLabel),
                    ],
                  ),
                  buildBackupSection(context),
                  if (appVersion != null)
                    SettingsSection(
                      tiles: [
                        SettingsTile(
                          title: Text(l10n.versionLabel),
                          value: Text(appVersion.text),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
        {
          '_startOfDay': _startOfDay,
          '_notifyAfterInactivity': _notifyAfterInactivity,
          '_habitualMemsCount': _habitualMemsCount,
          '_habitualMemsTimeRadius': _habitualMemsTimeRadius,
          '_habitualMemsLookback': _habitualMemsLookback,
          '_appVersion': _appVersion,
        },
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
