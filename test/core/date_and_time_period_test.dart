import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';

import '../helpers.dart';

void main() {
  group('Create instance', () {
    group(': Constructor', () {
      test(
        ': with start.',
        () {
          final start = DateAndTime.now();
          final dateAndTimePeriod = DateAndTimePeriod(
            start: start,
          );

          expect(dateAndTimePeriod.start, start);
          expect(dateAndTimePeriod.end, null);
        },
      );

      test(
        ': with end.',
        () {
          final end = DateAndTime.now();
          final dateAndTimePeriod = DateAndTimePeriod(
            end: end,
          );

          expect(dateAndTimePeriod.start, null);
          expect(dateAndTimePeriod.end, end);
        },
      );

      test(
        ': with start and end.',
        () {
          final now = DateAndTime.now();
          final dateAndTimePeriod = DateAndTimePeriod(start: now, end: now);

          expect(dateAndTimePeriod.start, now);
          expect(dateAndTimePeriod.end, now);
        },
      );

      test(
        ': with not all day start and all day end',
        () {
          final start = DateAndTime.now(allDay: false);
          final end = DateAndTime.now(allDay: true);

          final dateAndTimePeriod = DateAndTimePeriod(start: start, end: end);

          expect(dateAndTimePeriod.start, start);
          expect(dateAndTimePeriod.end, end);
        },
      );

      group(': throw error', () {
        test(': start and end are null.', () {
          expect(() => DateAndTimePeriod(), throwsArgumentError);
        });

        test(
          ': start is after end.',
          () {
            final start = DateAndTime.now();
            final end =
                DateAndTime.from(start.subtract(const Duration(days: 1)));

            expect(
              () => DateAndTimePeriod(start: start, end: end),
              throwsArgumentError,
            );
          },
        );
      });
    });

    test(
      ': startNow.',
      () {
        final now = DateAndTime.now();

        final dateAndTimePeriod = DateAndTimePeriod.startNow();

        expect(
          dateAndTimePeriod.start?.microsecondsSinceEpoch,
          greaterThanOrEqualTo(now.microsecondsSinceEpoch),
        );
        expect(dateAndTimePeriod.end, null);
      },
    );
  });

  test(
    'toString.',
    () {
      final now = DateAndTime.now();

      final dateAndTimePeriod = DateAndTimePeriod(start: null, end: now);

      expect(
        dateAndTimePeriod.toString(),
        '{'
        'start: ${dateAndTimePeriod.start.toString()}'
        ', end: ${dateAndTimePeriod.end.toString()}'
        '}',
      );
    },
  );

  group('Comparable', () {
    final now = DateTime.now();
    const oneDay = Duration(days: 1);

    final today = DateAndTime.from(now, timeOfDay: now);
    final yesterday = DateAndTime.from(now.subtract(oneDay), timeOfDay: now);
    final tomorrow = DateAndTime.from(now.add(oneDay), timeOfDay: now);

    final startOnly = DateAndTimePeriod(
      start: today,
    );
    group(': start only $startOnly', () {
      final startOnlyCase = {
        //    |-
        //o  |-
        DateAndTimePeriod(start: yesterday): 1,
        //o   |- same
        DateAndTimePeriod(start: today): 0,
        //o    |-
        DateAndTimePeriod(start: tomorrow): -1,
        //o -|
        DateAndTimePeriod(end: yesterday): 1,
        //o  -|
        DateAndTimePeriod(end: today): 1,
        //o   -|
        DateAndTimePeriod(end: tomorrow): -1,
        //o  |-|
        DateAndTimePeriod(start: yesterday, end: tomorrow): 1,
      };
      startOnlyCase.forEach((input, expected) {
        test(': with $input.', () {
          final result = startOnly.compareTo(input);

          expect(
            result,
            expected,
            reason: {
              startOnly,
              input,
            }.toString(),
          );
        });
      });
    });

    final endOnly = DateAndTimePeriod(
      end: DateAndTime.from(now, timeOfDay: now),
    );
    group(': end only $endOnly', () {
      final endOnlyCase = {
        //   -|
        //o  |-
        DateAndTimePeriod(start: yesterday): 1,
        //o   |-
        DateAndTimePeriod(start: today): -1,
        //o    |-
        DateAndTimePeriod(start: tomorrow): -1,
        //o -|
        DateAndTimePeriod(end: yesterday): 1,
        //o  -| same
        DateAndTimePeriod(end: today): 0,
        //o   -|
        DateAndTimePeriod(end: tomorrow): -1,
        //o  |-|
        DateAndTimePeriod(start: yesterday, end: tomorrow): -1,
      };
      endOnlyCase.forEach((input, expected) {
        test(': with $input.', () {
          final result = endOnly.compareTo(input);

          expect(
            result,
            expected,
            reason: {
              endOnly,
              input,
            }.toString(),
          );
        });
      });
    });

    final twoDaysAgo = yesterday.subtract(oneDay);
    final threeDaysAgo = twoDaysAgo.subtract(oneDay);
    final twoDaysLater = tomorrow.add(oneDay);
    final threeDaysLater = twoDaysLater.add(oneDay);
    final startAndEnd = DateAndTimePeriod(
      start: twoDaysAgo,
      end: twoDaysLater,
    );
    group(': start and end $startAndEnd', () {
      final inputs = {
        //    |---|
        //o  |-
        DateAndTimePeriod(start: threeDaysAgo): 1,
        //o   |-
        DateAndTimePeriod(start: twoDaysAgo): -1,
        //o     |-
        DateAndTimePeriod(start: today): -1,
        //o       |-
        DateAndTimePeriod(start: twoDaysLater): -1,
        //o        |-
        DateAndTimePeriod(start: threeDaysLater): -1,
        //o -|
        DateAndTimePeriod(end: threeDaysAgo): 1,
        //o  -|
        DateAndTimePeriod(end: twoDaysAgo): 1,
        //o    -|
        DateAndTimePeriod(end: today): 1,
        //o      -|
        DateAndTimePeriod(end: twoDaysLater): -1,
        //o       -|
        DateAndTimePeriod(end: threeDaysLater): -1,
        //o  ||
        DateAndTimePeriod(start: threeDaysAgo, end: twoDaysAgo): 1,
        //o  |--|
        DateAndTimePeriod(start: threeDaysAgo, end: today): 1,
        //o  |----|
        DateAndTimePeriod(start: threeDaysAgo, end: twoDaysLater): 1,
        //o  |-----|
        DateAndTimePeriod(start: threeDaysAgo, end: threeDaysLater): 1,
        //o   |-|
        DateAndTimePeriod(start: twoDaysAgo, end: today): 1,
        //o   |---| same
        DateAndTimePeriod(start: twoDaysAgo, end: twoDaysLater): 0,
        //o   |----|
        DateAndTimePeriod(start: twoDaysAgo, end: threeDaysLater): -1,
        //o    |-|
        DateAndTimePeriod(start: yesterday, end: tomorrow): -1,
        //o    |--|
        DateAndTimePeriod(start: yesterday, end: twoDaysLater): -1,
        //o    |---|
        DateAndTimePeriod(start: yesterday, end: threeDaysLater): -1,
      };
      inputs.forEach((input, expected) {
        test(': with $input.', () {
          final result = startAndEnd.compareTo(input);

          expect(
            result,
            expected,
            reason: {
              startAndEnd,
              input,
            }.toString(),
          );
        });
      });
    });
    //e   -|
    //   |-|
  });

  group(": compare", () {
    for (var testCase in [
      TestCase(
        name: "both are not null",
        [
          DateAndTimePeriod.startNow(),
          DateAndTimePeriod(end: DateAndTime.now()),
        ],
        DateAndTimePeriod.startNow()
            .compareTo(DateAndTimePeriod(end: DateAndTime.now())),
      ),
      TestCase(
        name: "both are null",
        [null, null],
        0,
      ),
      TestCase(
        name: "a is null, b is not null",
        [null, DateAndTimePeriod.startNow()],
        1,
      ),
      TestCase(
        name: "a is not null, b is null",
        [DateAndTimePeriod.startNow(), null],
        -1,
      ),
    ]) {
      test(
        ": ${testCase.name}.",
        () => expect(
          DateAndTimePeriod.compare(testCase.input[0], testCase.input[1]),
          testCase.expected,
        ),
      );
    }
  });

  group('duration', () {
    test('is zero when either bound is missing', () {
      final at = DateAndTime(2024, 1, 1, 1);

      expect(DateAndTimePeriod(start: at).duration, Duration.zero);
      expect(DateAndTimePeriod(end: at).duration, Duration.zero);
    });

    test('is the span from start to end', () {
      final start = DateAndTime(2024, 1, 1, 1);
      final end = DateAndTime(2024, 1, 1, 2, 3, 4);

      expect(
        DateAndTimePeriod(start: start, end: end).duration,
        end.difference(start),
      );
    });
  });

  group('compareWithDateAndTime', () {
    final start = DateAndTime(2024, 1, 1, 1);
    final end = DateAndTime(2024, 1, 2, 3);
    final later = DateTime(2024, 1, 3);

    test('start only treats null as equal and otherwise compares the start', () {
      final period = DateAndTimePeriod(start: start);

      expect(period.compareWithDateAndTime(null), 0);
      expect(period.compareWithDateAndTime(later), start.compareTo(later));
    });

    test('end only treats null as equal and otherwise compares the end', () {
      final period = DateAndTimePeriod(end: end);

      expect(period.compareWithDateAndTime(null), 0);
      expect(period.compareWithDateAndTime(later), end.compareTo(later));
    });

    test('start and end compares by the end', () {
      final period = DateAndTimePeriod(start: start, end: end);

      expect(period.compareWithDateAndTime(null), 0);
      expect(period.compareWithDateAndTime(later), end.compareTo(later));
    });
  });

  group('includesStart', () {
    final period = DateAndTimePeriod(
      start: DateAndTime(2026, 10, 7, 5),
      end: DateAndTime(2026, 10, 14, 5),
    );

    test('includes the start and excludes the end', () {
      expect(period.includesStart(DateAndTime(2026, 10, 7, 5)), isTrue);
      expect(period.includesStart(DateAndTime(2026, 10, 13, 12)), isTrue);
      expect(period.includesStart(DateAndTime(2026, 10, 14, 5)), isFalse);
      expect(period.includesStart(DateAndTime(2026, 10, 7, 4)), isFalse);
    });

    test('is false when either bound is missing', () {
      expect(
        DateAndTimePeriod(start: DateAndTime(2026, 10, 7, 5))
            .includesStart(DateAndTime(2026, 10, 7, 5)),
        isFalse,
      );
    });
  });
}
