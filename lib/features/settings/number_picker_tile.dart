import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:settings_ui/settings_ui.dart';

SettingsTile buildNumberPickerTile(
  BuildContext context,
  String label,
  int? value,
  void Function(int? picked) onChanged, {
  required int min,
  required int max,
  required int defaultValue,
  required IconData icon,
}) =>
    v(
      () => SettingsTile.navigation(
        leading: Icon(icon),
        title: Text(label),
        value: value == null ? null : Text(value.toString()),
        onPressed: (context) async {
          onChanged(
            await _showNumberPicker(
              context,
              value,
              min: min,
              max: max,
              defaultValue: defaultValue,
            ),
          );
        },
      ),
      {
        'context': context,
        'label': label,
        'value': value,
      },
    );

Future<int?> _showNumberPicker(
  BuildContext context,
  int? value, {
  required int min,
  required int max,
  required int defaultValue,
}) =>
    v(
      () async {
        final column = NumberPickerColumn(
          begin: min,
          end: max,
          initValue: value ?? defaultValue,
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
        'value': value,
        'min': min,
        'max': max,
      },
    );
