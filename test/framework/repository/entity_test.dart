import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/repository/entity.dart';

const _name = 'Entity test';

class TestSample {
  final bool a;

  TestSample(this.a);
}

class TestSampleEntity with EntityV1<TestSample> {
  static List<String> fieldNames = ['a'];

  TestSampleEntity(TestSample value) {
    this.value = value;
  }

  @override
  Map<String, dynamic> get toMap => {
        fieldNames[0]: value.a,
      };

  @override
  EntityV1<TestSample> updatedWith(TestSample Function(TestSample v) update) =>
      TestSampleEntity(update(value));
}

void main() => group(
      _name,
      () {
        test(
          '#new',
          () {
            const a = false;

            final testObject = TestSampleEntity(TestSample(a));

            expect(testObject.value.a, equals(a));
          },
        );

        test(
          '#toMap',
          () {
            const a = false;

            final testObject = TestSampleEntity(TestSample(a));

            expect(
                testObject.toMap, equals({TestSampleEntity.fieldNames[0]: a}));
          },
        );
      },
    );
