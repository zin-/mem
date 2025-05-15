import 'package:flutter/material.dart';
import 'package:mem/framework/date_and_time/seconds_of_time_picker.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:settings_ui/settings_ui.dart';

SettingsTile buildNotifyAfterInactivity(
  BuildContext context,
  int? notifyAfterInactivity,
  final void Function(int? picked) onNotifyAfterInactivityChanged,
) =>
    v(
      () {
        final l10n = buildL10n(context);

        return SettingsTile.navigation(
          leading: Icon(Icons.add_alert),
          title: Text(l10n.notifyAfterInactivityLabel),
          value: notifyAfterInactivity == null
              ? null
              : Text(formatSecondsOfTime(notifyAfterInactivity)),
          onPressed: (context) async {
            onNotifyAfterInactivityChanged(
              await showSecondsOfTimePicker(context, null),
            );
          },
        );
      },
      {
        'context': context,
      },
    );
