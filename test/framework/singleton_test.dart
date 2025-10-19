import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/singleton.dart';

class TestSample {
  TestSample._(); // private

  factory TestSample() => Singleton.of(() => TestSample._());
}

void main() => group('Singleton test', () {
      test('create singleton object.', () {
        final a = TestSample();
        final b = TestSample();

        expect(a, isA<TestSample>());
        expect(b, isA<TestSample>());

        expect(identical(a, b), isTrue);
      });
    });
