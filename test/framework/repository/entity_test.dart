import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/repository/entity.dart';

const _name = 'Entity test';

class _TestObject {
  final bool a;

  _TestObject(this.a);
}

class TestObjectEntity extends _TestObject with Entity {
  static List<String> fieldNames = ['a'];

  TestObjectEntity(super.a);

  TestObjectEntity.fromMap(Map<String, dynamic> map)
      : super(map[TestObjectEntity.fieldNames[0]]);

  @override
  Map<String, dynamic> get toMap => {fieldNames[0]: a};

  @override
  TestObjectEntity copiedWith({bool Function()? a}) =>
      TestObjectEntity(a == null ? this.a : a());
}

void main() => group(
      _name,
      () {
        test(
          '#new',
          () {
            const a = false;

            final testObject = TestObjectEntity(a);

            expect(testObject.a, equals(a));
          },
        );

        test(
          '#fromMap',
          () {
            final map = {TestObjectEntity.fieldNames[0]: false};

            final testObject = TestObjectEntity.fromMap(map);

            expect(testObject.a, equals(map[TestObjectEntity.fieldNames[0]]));
          },
        );

        test(
          '#toMap',
          () {
            const a = false;

            final testObject = TestObjectEntity(a);

            expect(
                testObject.toMap, equals({TestObjectEntity.fieldNames[0]: a}));
          },
        );

        test(
          '#==',
          () {
            const a = false;
            const b = false;

            final testObjectA = TestObjectEntity(a);
            final testObjectB = TestObjectEntity(b);

            expect(testObjectA, equals(testObjectB));
          },
        );

        test(
          '#copiedWith',
          () {
            final from = TestObjectEntity(false);

            final copied = from.copiedWith(a: () => true);

            expect(copied.a, equals(true));
          },
        );
      },
    );
