import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:settings_ui/settings_ui.dart';

SettingsTile buildHabitualMemsCount(
  BuildContext context,
  int? habitualMemsCount,
  final void Function(int? picked) onHabitualMemsCountChanged,
) =>
    v(
      () {
        final l10n = buildL10n(context);

        return SettingsTile.navigation(
          leading: const Icon(Icons.schedule),
          title: Text(l10n.habitualMemsCountLabel),
          value: habitualMemsCount == null
              ? null
              : Text(habitualMemsCount.toString()),
          onPressed: (context) async {
            onHabitualMemsCountChanged(
              await _showHabitualMemsCountPicker(context, habitualMemsCount),
            );
          },
        );
      },
      {
        'context': context,
      },
    );

Future<int?> _showHabitualMemsCountPicker(
  BuildContext context,
  int? habitualMemsCount,
) =>
    v(
      () async {
        final column = NumberPickerColumn(
          begin: minHabitualMemsCount,
          end: maxHabitualMemsCount,
          initValue: habitualMemsCount ?? defaultHabitualMemsCount,
        );
        final picked = await Picker(
          confirmText: 'OK',
          adapter: NumberPickerAdapter(
            data: [column],
          ),
        ).showModal<List<int>>(context);

        if (picked == null) {
          return null;
        } else {
          return column.valueOf(picked[0]);
        }
      },
      {
        'context': context,
        'habitualMemsCount': habitualMemsCount,
      },
    );
