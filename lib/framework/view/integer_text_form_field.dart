import 'package:flutter/material.dart';

class IntegerTextFormField extends StatelessWidget {
  final int initialValue;
  final void Function(int?)? onChanged;
  final int? minValue;
  final int? maxValue;
  final String? emptyErrorMessage;
  final String? nonNumericErrorMessage;
  final String Function(int)? belowMinErrorMessage;
  final String Function(int)? aboveMaxErrorMessage;
  final AutovalidateMode autovalidateMode;

  const IntegerTextFormField(
    this.initialValue, {
    super.key,
    this.onChanged,
    this.minValue,
    this.maxValue,
    this.emptyErrorMessage,
    this.nonNumericErrorMessage,
    this.belowMinErrorMessage,
    this.aboveMaxErrorMessage,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  String _getEmptyErrorMessage() => emptyErrorMessage ?? 'Required';

  String _getNonNumericErrorMessage() =>
      nonNumericErrorMessage ?? 'Numbers only';

  String _getBelowMinErrorMessage(int min) =>
      belowMinErrorMessage?.call(min) ?? 'Min: $min';

  String _getAboveMaxErrorMessage(int max) =>
      aboveMaxErrorMessage?.call(max) ?? 'Max: $max';

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue.toString(),
      keyboardType: TextInputType.number,
      autovalidateMode: autovalidateMode,
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue == null) {
          onChanged?.call(null);
          return;
        }

        if (minValue != null && intValue < minValue!) {
          onChanged?.call(null);
          return;
        }

        if (maxValue != null && intValue > maxValue!) {
          onChanged?.call(null);
          return;
        }

        onChanged?.call(intValue);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return _getEmptyErrorMessage();
        }

        final intValue = int.tryParse(value);
        if (intValue == null) {
          return _getNonNumericErrorMessage();
        }

        if (minValue != null && intValue < minValue!) {
          return _getBelowMinErrorMessage(minValue!);
        }

        if (maxValue != null && intValue > maxValue!) {
          return _getAboveMaxErrorMessage(maxValue!);
        }

        return null;
      },
    );
  }
}
