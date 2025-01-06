import 'package:flutter/material.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:settings_ui/settings_ui.dart';

SettingsTile buildNotifyAfterInactivity(BuildContext context) => v(
      () {
        final l10n = buildL10n(context);

        return SettingsTile.navigation(
          leading: Icon(Icons.add_alert),
          title: Text(l10n.notifyAfterInactivityLabel),
        );
      },
      {
        'context': context,
      },
    );
