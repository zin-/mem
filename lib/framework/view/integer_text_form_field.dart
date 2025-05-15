import 'package:flutter/material.dart';
import 'package:mem/generated/l10n/app_localizations.dart';

class IntegerTextFormField extends StatelessWidget {
  final int initialValue;
  final void Function(int?)? onChanged;
  final int maxValue;

  const IntegerTextFormField(
    this.initialValue, {
    this.onChanged,
    this.maxValue = 999999,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      initialValue: initialValue.toString(),
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.isEmpty) {
          return null;
        }
        final value = int.tryParse(v);
        if (value == null) {
          return l10n.targetInputNumberError;
        }
        if (value < 0) {
          return l10n.targetInputNegativeError;
        }
        if (value > maxValue) {
          return l10n.targetInputMaxCountError(maxValue);
        }
        return null;
      },
      onChanged: (v) => onChanged?.call(() {
        final value = int.tryParse(v);
        if (value == null || value < 0 || value > maxValue) {
          return null;
        }
        return value;
      }()),
    );
  }
}
