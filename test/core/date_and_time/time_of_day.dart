import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/date_and_time/time_of_day.dart';

import '../../helpers.dart';

void main() => group(
      'TimeOfDayExt',
      () {
        group(
          'isAfterWithStartOfDay',
          () {
            final other1 = TimeOfDay(hour: 3, minute: 0);
            final startOfDay = TimeOfDay(hour: 5, minute: 0);
            final other2 = TimeOfDay(hour: 7, minute: 0);
            for (final testCase in [
              TestCase(TimeOfDay(hour: 2, minute: 0), true),
              TestCase(TimeOfDay(hour: 4, minute: 0), true),
            ]) {
              test(
                '${testCase.input}, $other1',
                () {
                  expect(
                    testCase.input.isAfterWithStartOfDay(other1, startOfDay),
                    equals(testCase.expected),
                  );
                },
              );
              test(
                '${testCase.input}, $other2',
                () {
                  expect(
                    testCase.input.isAfterWithStartOfDay(other2, startOfDay),
                    equals(testCase.expected),
                  );
                },
              );
            }

            test(
              '${TimeOfDay(hour: 6, minute: 0)}, $other1',
              () {
                expect(
                  TimeOfDay(hour: 6, minute: 0)
                      .isAfterWithStartOfDay(other1, startOfDay),
                  isTrue,
                );
              },
            );
            test(
              '${TimeOfDay(hour: 6, minute: 0)}, $other2',
              () {
                expect(
                  TimeOfDay(hour: 6, minute: 0)
                      .isAfterWithStartOfDay(other2, startOfDay),
                  isFalse,
                );
              },
            );
          },
        );
      },
    );
