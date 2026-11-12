import 'package:mem/framework/date_and_time/period.dart';

class TargetShownValue {
  final int value;
  final bool approximate;

  TargetShownValue._(this.value, {required this.approximate});

  static TargetShownValue? of({
    required int value,
    required Period period,
    required Period shownIn,
  }) {
    if (period == shownIn) {
      return TargetShownValue._(value, approximate: false);
    }

    final fromDays = period.fixedDays;
    final toDays = shownIn.fixedDays;
    if (fromDays == null || toDays == null) return null;

    final numerator = value * toDays;
    return TargetShownValue._(
      _roundedQuotient(numerator, fromDays),
      approximate: numerator % fromDays != 0,
    );
  }

  static int _roundedQuotient(int numerator, int denominator) =>
      (numerator + denominator ~/ 2) ~/ denominator;
}
