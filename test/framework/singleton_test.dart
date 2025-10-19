import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'singleton_test.mocks.dart';

class TestSample {
  TestSample._(); // private

  factory TestSample() => Singleton.of(() => TestSample._());

  String sampleMethod() => 'sample';
}

@GenerateMocks([TestSample])
void main() => group('Singleton test', () {
      test('create singleton object.', () {
        final a = TestSample();
        final b = TestSample();

        expect(a, isA<TestSample>());
        expect(b, isA<TestSample>());

        expect(identical(a, b), isTrue);
      });

      test('override singleton object.', () {
        expect(TestSample().sampleMethod(), 'sample');

        final mockTestSample = MockTestSample();
        Singleton.override<TestSample>(mockTestSample);
        when(mockTestSample.sampleMethod()).thenReturn('mock');

        final a = TestSample();

        expect(a, isA<MockTestSample>());
        expect(TestSample().sampleMethod(), 'mock');
      });
    });
