import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:settings_ui/settings_ui.dart';

import 'backup_client.dart';

AbstractSettingsTile buildGenerateBackupTile(BuildContext context) => v(
      () {
        final l10n = buildL10n(context);

        return SettingsTile.navigation(
          leading: const Icon(Icons.backup),
          title: Text(l10n.backupLabel),
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
        );
      },
      {'context': context},
    );
