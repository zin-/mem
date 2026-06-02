import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';

void main() {
  group('TargetEntity', () {
    test('SavedTargetEntityV1 reads map fallback and toEntityV2', () {
      final createdAt = DateTime(2024, 1, 1);
      final updatedAt = DateTime(2024, 1, 2);
      final archivedAt = DateTime(2024, 1, 3);
      final saved = SavedTargetEntityV1({
        'id': 1,
        'mems_id': 10,
        'type': TargetType.moreThan.name,
        'unit': TargetUnit.time.name,
        'value': 30,
        'period': Period.aWeek.name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      });

      expect(saved.toMap, containsPair('memId', 10));
      expect(saved.toMap, containsPair('type', TargetType.moreThan.name));
      expect(saved.toMap, containsPair('unit', TargetUnit.time.name));
      expect(saved.toMap, containsPair('period', Period.aWeek.name));
      final entity = saved.toEntityV2();
      expect(entity.memId, 10);
      expect(entity.targetType, TargetType.moreThan);
      expect(entity.targetUnit, TargetUnit.time);
      expect(entity.period, Period.aWeek);
      expect(entity.id, 1);
    });

    test('fromEntityV2 and updatedWith keep base columns', () {
      final createdAt = DateTime(2024, 2, 1);
      final updatedAt = DateTime(2024, 2, 2);
      final archivedAt = DateTime(2024, 2, 3);
      final saved = SavedTargetEntityV1.fromEntityV2(
        TargetEntity(
          2,
          TargetType.equalTo,
          TargetUnit.count,
          5,
          Period.aDay,
          9,
          createdAt,
          updatedAt,
          archivedAt,
        ),
      );

      final changed = saved.updatedWith(
        (v) => Target(
          memId: v.memId,
          targetType: TargetType.lessThan,
          targetUnit: TargetUnit.time,
          value: 100,
          period: Period.aMonth,
        ),
      );

      expect(changed.id, 9);
      expect(changed.createdAt, createdAt);
      expect(changed.updatedAt, updatedAt);
      expect(changed.archivedAt, archivedAt);
      expect(changed.value.targetType, TargetType.lessThan);
      expect(changed.value.targetUnit, TargetUnit.time);
      expect(changed.value.period, Period.aMonth);
    });

    test('TargetEntity fromTuple and insertable/updateable', () {
      final now = DateTime(2024, 3, 1);
      final entity = TargetEntity.fromTuple(
        _FakeRow(
          id: 3,
          memId: 4,
          type: TargetType.equalTo.name,
          unit: TargetUnit.count.name,
          value: 7,
          period: Period.threeMonth.name,
          createdAt: now,
          updatedAt: now,
          archivedAt: null,
        ),
      );
      expect(entity.memId, 4);
      expect(entity.targetType, TargetType.equalTo);
      expect(entity.targetUnit, TargetUnit.count);
      expect(entity.period, Period.threeMonth);

      final insertable = convertIntoTargetsInsertable(
        Target(
          memId: null,
          targetType: TargetType.lessThan,
          targetUnit: TargetUnit.time,
          value: 12,
          period: Period.aYear,
        ),
      );
      expect(insertable.memId.value, 0);
      expect(insertable.type.value, TargetType.lessThan.name);
      expect(insertable.unit.value, TargetUnit.time.name);
      expect(insertable.period.value, Period.aYear.name);
      expect(insertable.createdAt.value, isNotNull);

      final updateable = convertIntoTargetsUpdateable(
        TargetEntity(
          null,
          TargetType.moreThan,
          TargetUnit.count,
          99,
          Period.all,
          8,
          now,
          null,
          now,
        ),
      );
      expect(updateable.id.value, 8);
      expect(updateable.memId.value, 0);
      expect(updateable.type.value, TargetType.moreThan.name);
      expect(updateable.unit.value, TargetUnit.count.name);
      expect(updateable.period.value, Period.all.name);
      expect(updateable.archivedAt.value, now);
      expect(updateable.updatedAt.value, isNotNull);
    });
  });
}

class _FakeRow {
  final int id;
  final int memId;
  final String type;
  final String unit;
  final int value;
  final String period;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  _FakeRow({
    required this.id,
    required this.memId,
    required this.type,
    required this.unit,
    required this.value,
    required this.period,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });
}
