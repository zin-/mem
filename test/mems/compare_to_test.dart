import 'package:flutter_test/flutter_test.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/mems/mem.dart';
import 'package:mem/mems/mem_entity.dart';

const _name = 'Mem test: compareTo';

void main() => group(_name, () {
      group(': Mem', () {
        test(': 0.', () {
          final a = Mem("$_name - a", null, null);
          final b = Mem("$_name - b", null, null);

          final result = a.compareTo(b);

          expect(result, equals(0));
        });

        test(': active act.', () {
          final memA = Mem("$_name - a", null, null);
          final memB = Mem("$_name - b", null, null);
          final actB = Act(0, DateAndTimePeriod(start: DateAndTime.now()));

          final result = memA.compareTo(memB, otherLatestAct: actB);

          expect(result, equals(1));
        });

        test(': is done.', () {
          final memA = Mem("$_name - a", null, null);
          final memB = Mem("$_name - b", DateAndTime.now(), null);

          final result = memA.compareTo(memB);

          expect(result, equals(-1));
        });
      });

      group(": SavedMemEntity", () {
        test(': id', () {
          final a = SavedMemEntity("$_name - a", null, null)
            ..id = 2
            ..createdAt = DateTime.now()
            ..updatedAt = null
            ..archivedAt = null;
          final b = SavedMemEntity("$_name - b", null, null)
            ..id = 1
            ..createdAt = DateTime.now()
            ..updatedAt = null
            ..archivedAt = null;

          final result = a.compareTo(b);

          expect(result, equals(1));
        });

        test(': isArchived', () {
          final a = SavedMemEntity("$_name - a", null, null)
            ..id = 0
            ..createdAt = DateTime.now()
            ..updatedAt = null
            ..archivedAt = DateTime.now();
          final b = SavedMemEntity("$_name - b", null, null)
            ..id = 0
            ..createdAt = DateTime.now()
            ..updatedAt = null
            ..archivedAt = null;

          final result = a.compareTo(b);

          expect(result, equals(1));
        });
      });
    });
