import 'package:flutter/material.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/actions.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final String _startOfDayKey = "start_od_day";
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
                                ? await remove(_startOfDayKey)
                                : await save(
                                    _startOfDayKey,
                                    picked.serialize(),
                                  );
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
          final startOfDay = await loadByKey(_startOfDayKey);

          if (startOfDay is String) {
            setState(
              () => _startOfDay = TimeOfDayExtension.deserialize(startOfDay),
            );
          }
        },
      );
}

extension TimeOfDayExtension on TimeOfDay {
  static deserialize(String text) => v(
        () {
          final hourAndMinute =
              text.split(":").map((e) => int.parse(e)).toList();
          return TimeOfDay(
            hour: hourAndMinute[0],
            minute: hourAndMinute[1],
          );
        },
        {"text": text},
      );

  String serialize() => v(
        () => "$hour:$minute",
        toString(),
      );
}
