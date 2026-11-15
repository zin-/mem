import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_preposts/mem_prepost.dart';
import 'package:mem/features/mem_preposts/mem_prepost_entity.dart';

void main() {
  group('MemPrePost', () {
    test('of returns null when an end or minutes is missing', () {
      expect(
        MemPrePost.of(sourceMemId: null, targetMemId: 2, minutes: 15),
        isNull,
      );
      expect(
        MemPrePost.of(sourceMemId: 1, targetMemId: null, minutes: 15),
        isNull,
      );
      expect(
        MemPrePost.of(sourceMemId: 1, targetMemId: 2, minutes: null),
        isNull,
      );
    });
  });

  group('MemPrePostEntity', () {
    test('MemPrePostEntityV1.by and toMap', () {
      final entity = MemPrePostEntityV1.by(
        null,
        2,
        15,
      );

      expect(entity.value.sourceMemId, 0);
      expect(entity.value.targetMemId, 2);
      expect(entity.toMap['minutes'], 15);
    });

    test('SavedMemPrePostEntityV1 map fallback and toEntityV2', () {
      final createdAt = DateTime(2024, 1, 1);
      final updatedAt = DateTime(2024, 1, 2);
      final archivedAt = DateTime(2024, 1, 3);
      final saved = SavedMemPrePostEntityV1({
        'id': 9,
        'source_mems_id': 10,
        'target_mems_id': 11,
        'minutes': 12,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      });

      expect(saved.value.sourceMemId, 10);
      expect(saved.value.targetMemId, 11);
      expect(saved.value.minutes, 12);
      expect(saved.toEntityV2().id, 9);
      expect(saved.toEntityV2().sourceMemId, 10);
      expect(saved.toEntityV2().targetMemId, 11);
    });

    test('fromEntityV2 and fromTuple', () {
      final now = DateTime(2024, 2, 1);
      final saved = SavedMemPrePostEntityV1.fromEntityV2(
        MemPrePostEntity(
          20,
          21,
          30,
          3,
          now,
          now,
          null,
        ),
      );
      expect(saved.id, 3);
      expect(saved.value.sourceMemId, 20);

      final fromTuple = MemPrePostEntity.fromTuple(
        _FakeRow(
          id: 4,
          sourceMemId: 31,
          targetMemId: 32,
          minutes: 33,
          createdAt: now,
          updatedAt: now,
          archivedAt: null,
        ),
      );
      expect(fromTuple.id, 4);
      expect(fromTuple.minutes, 33);
    });

    test('insertable and updateable convert fields', () {
      final insertable = convertIntoMemPrePostsInsertable(
        MemPrePost.of(sourceMemId: 1, targetMemId: 2, minutes: 3)!,
      );
      expect(insertable.sourceMemId.value, 1);
      expect(insertable.targetMemId.value, 2);
      expect(insertable.minutes.value, 3);
      expect(insertable.createdAt.value, isNotNull);

      final updateable = convertIntoMemPrePostsUpdateable(
        MemPrePostEntity(
          null,
          null,
          5,
          6,
          DateTime(2024, 3, 1),
          null,
          DateTime(2024, 3, 2),
        ),
      );
      expect(updateable.sourceMemId.value, 0);
      expect(updateable.targetMemId.value, 0);
      expect(updateable.minutes.value, 5);
      expect(updateable.archivedAt.value, DateTime(2024, 3, 2));
      expect(updateable.updatedAt.value, isNotNull);
    });

    test('updatedWith keeps the saved id', () {
      final now = DateTime(2024, 4, 1);
      final saved = SavedMemPrePostEntityV1.fromEntityV2(
        MemPrePostEntity(1, 2, 10, 8, now, null, null),
      ).updatedWith((v) => v.withSourceMemId(4));

      expect(saved.id, 8);
      expect(saved.value.sourceMemId, 4);
      expect(saved.value.targetMemId, 2);
      expect(saved.value.minutes, 10);
    });
  });
}

class _FakeRow {
  final int id;
  final int sourceMemId;
  final int targetMemId;
  final int minutes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  _FakeRow({
    required this.id,
    required this.sourceMemId,
    required this.targetMemId,
    required this.minutes,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });
}
