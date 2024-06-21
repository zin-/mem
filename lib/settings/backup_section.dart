import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:settings_ui/settings_ui.dart';

import 'backup_client.dart';

AbstractSettingsSection buildBackupSection(BuildContext context) => v(
      () => SettingsSection(
        title: Text(buildL10n(context).backupLabel),
        tiles: [
          _buildGenerateBackupTile(context),
        ],
      ),
      {'context': context},
    );

AbstractSettingsTile _buildGenerateBackupTile(BuildContext context) => v(
      () => SettingsTile.navigation(
        leading: const Icon(Icons.backup),
        title: Text(buildL10n(context).createBackupLabel),
        onPressed: (context) => v(
          () {
            BackupClient()
                .createBackup()
                .whenComplete(
                  () => v(
                    () => Navigator.of(context).pop(),
                  ),
                )
                .then(
                  (result) => v(
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.toString()),
                      ),
                    ),
                    {
                      "result": result,
                    },
                  ),
                );

            showGeneralDialog(
              context: context,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
      {'context': context},
    );
