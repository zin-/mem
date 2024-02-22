import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/settings/actions.dart';
import 'package:mem/settings/keys.dart';
import 'package:mem/settings/states.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => i(
        () => _SettingsPage(
          startOfDay: ref.watch(startOfDayProvider),
          onStartOfDayChanged: (TimeOfDay? picked) => v(
            () async {
              await update(startOfDayKey, picked);
              ref.read(startOfDayProvider.notifier).updatedBy(picked);
            },
            picked,
          ),
        ),
      );
}

class _SettingsPage extends StatelessWidget {
  final TimeOfDay? _startOfDay;
  final void Function(TimeOfDay? picked) _onStartOfDayChanged;

  const _SettingsPage({
    required TimeOfDay? startOfDay,
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
                      SettingsTile.navigation(
                        leading: const Icon(Icons.start),
                        title: Text(l10n.startOfDayLabel),
                        onPressed: (context) => v(
                          () async => _onStartOfDayChanged(
                            await showTimePicker(
                              context: context,
                              initialTime: _startOfDay ?? TimeOfDay.now(),
                            ),
                          ),
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
        {"_startOfDay": _startOfDay},
      );
}
