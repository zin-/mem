import 'package:flutter/material.dart';

class IntegerTextFormField extends StatelessWidget {
  final int initialValue;
  final void Function(int?)? onChanged;
  final int? minValue;
  final int? maxValue;
  final String? emptyErrorMessage;
  final String? nonNumericErrorMessage;
  final String? belowMinErrorMessage;
  final String? aboveMaxErrorMessage;
  final AutovalidateMode? autovalidateMode;

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

  String _getEmptyErrorMessage() =>
      emptyErrorMessage ?? 'Please enter a number';

  String _getNonNumericErrorMessage() =>
      nonNumericErrorMessage ?? 'Please enter a number';

  String _getBelowMinErrorMessage() =>
      belowMinErrorMessage ??
      'Please enter a value greater than or equal to $minValue';

  String _getAboveMaxErrorMessage() =>
      aboveMaxErrorMessage ??
      'Please enter a value less than or equal to $maxValue';

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: key,
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
          return _getBelowMinErrorMessage();
        }

        if (maxValue != null && intValue > maxValue!) {
          return _getAboveMaxErrorMessage();
        }

        return null;
      },
    );
  }
}
