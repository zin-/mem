import 'package:mem/features/targets/target_shown_value.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:test/test.dart';

void main() {
  group('TargetShownValue', () {
    test('keeps the value when the periods match', () {
      final shown = TargetShownValue.of(
        value: 5,
        period: Period.aWeek,
        shownIn: Period.aWeek,
      );

      expect(shown?.value, 5);
      expect(shown?.approximate, isFalse);
      expect(
        TargetShownValue.of(
          value: 5,
          period: Period.all,
          shownIn: Period.all,
        )?.value,
        5,
      );
    });

    test('is absent when either period has no fixed length', () {
      expect(
        TargetShownValue.of(
          value: 5,
          period: Period.all,
          shownIn: Period.aWeek,
        ),
        isNull,
      );
      expect(
        TargetShownValue.of(
          value: 5,
          period: Period.aDay,
          shownIn: Period.all,
        ),
        isNull,
      );
    });

    test('scales an exact multiple toward a longer period', () {
      final shown = TargetShownValue.of(
        value: 3,
        period: Period.aDay,
        shownIn: Period.aWeek,
      );

      expect(shown?.value, 21);
      expect(shown?.approximate, isFalse);
      expect(
        TargetShownValue.of(
          value: Duration(hours: 1).inSeconds,
          period: Period.aDay,
          shownIn: Period.aWeek,
        )?.value,
        Duration(hours: 7).inSeconds,
      );
    });

    test('rounds toward a shorter period', () {
      final weekToDay = TargetShownValue.of(
        value: 5,
        period: Period.aWeek,
        shownIn: Period.aDay,
      );
      final threePerWeek = TargetShownValue.of(
        value: 3,
        period: Period.aWeek,
        shownIn: Period.aDay,
      );

      expect(weekToDay?.value, 1);
      expect(weekToDay?.approximate, isTrue);
      expect(threePerWeek?.value, 0);
      expect(threePerWeek?.approximate, isTrue);
    });

    test('rounds half up', () {
      final shown = TargetShownValue.of(
        value: 14,
        period: Period.aMonth,
        shownIn: Period.aDay,
      );

      expect(shown?.value, 1);
      expect(shown?.approximate, isTrue);
    });

    test('scales three months into a year', () {
      final shown = TargetShownValue.of(
        value: 1,
        period: Period.threeMonth,
        shownIn: Period.aYear,
      );

      expect(shown?.value, 4);
      expect(shown?.approximate, isTrue);
    });

    test('scales a year into shorter periods', () {
      TargetShownValue? shown(Period shownIn) => TargetShownValue.of(
            value: 10,
            period: Period.aYear,
            shownIn: shownIn,
          );

      expect(shown(Period.aDay)?.value, 0);
      expect(shown(Period.aWeek)?.value, 0);
      expect(shown(Period.aMonth)?.value, 1);
      expect(shown(Period.threeMonth)?.value, 2);
      expect(shown(Period.aDay)?.approximate, isTrue);
      expect(shown(Period.aMonth)?.approximate, isTrue);
    });
  });
}
