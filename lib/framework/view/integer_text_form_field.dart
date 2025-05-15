import 'package:flutter/material.dart';

class IntegerTextFormField extends StatelessWidget {
  final int initialValue;
  final void Function(int?)? onChanged;
  final int minValue;
  final int maxValue;
  final String? Function(String?)? errorMessageBuilder;

  const IntegerTextFormField(
    this.initialValue, {
    this.onChanged,
    this.minValue = 0,
    this.maxValue = 999999,
    this.errorMessageBuilder,
    super.key,
  });

  String? _getErrorMessage(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return errorMessageBuilder?.call(value) ?? 'Please enter a number';
    }
    if (intValue < minValue) {
      return errorMessageBuilder?.call(value) ??
          'Please enter a value greater than or equal to $minValue';
    }
    if (intValue > maxValue) {
      return errorMessageBuilder?.call(value) ??
          'Please enter a value less than or equal to $maxValue';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue.toString(),
      keyboardType: TextInputType.number,
      validator: _getErrorMessage,
      onChanged: (v) => onChanged?.call(() {
        final value = int.tryParse(v);
        if (value == null || value < minValue || value > maxValue) {
          return null;
        }
        return value;
      }()),
    );
  }
}
