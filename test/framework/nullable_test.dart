import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/nullable.dart';

void main() => group('nullableCompare', () {
      test('both null returns 0', () {
        expect(nullableCompare<String>(null, null), 0);
      });

      test('null sorts after non-null', () {
        expect(nullableCompare<String>('a', null), -1);
        expect(nullableCompare<String>(null, 'a'), 1);
      });

      test('compares non-null values', () {
        expect(nullableCompare<String>('a', 'b'), lessThan(0));
        expect(nullableCompare<String>('b', 'a'), greaterThan(0));
        expect(nullableCompare<String>('same', 'same'), 0);
      });
    });
