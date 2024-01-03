import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/actions.dart';
import 'package:mem/settings/keys.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay? _startOfDay;

  @override
  void initState() => v(
        () {
          super.initState();
          _loadPreferences();
        },
      );

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
                      SettingsTile.navigation(
                        leading: const Icon(Icons.start),
                        title: Text(l10n.start_of_day_label),
                        onPressed: (context) => v(
                          () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );

                            setState(() {
                              _startOfDay = picked;
                            });

                            return picked == null
                                ? await remove(startOfDayKey)
                                : await save(startOfDayKey, picked);
                          },
                        ),
                        value: _startOfDay == null
                            ? null
                            : Text(_startOfDay!.format(context)),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );

  Future<void> _loadPreferences() => v(
        () async {
          final startOfDay = await loadByKey(startOfDayKey);

          setState(
            () => _startOfDay = startOfDay as TimeOfDay?,
          );
        },
      );
}
