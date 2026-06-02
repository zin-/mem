import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';

void main() {
  group('MemRelationEntity', () {
    test('MemRelationEntityV1.by and toMap', () {
      final entity = MemRelationEntityV1.by(
        null,
        2,
        MemRelationType.prePost,
        15,
      );

      expect(entity.value.sourceMemId, 0);
      expect(entity.value.targetMemId, 2);
      expect(entity.toMap['type'], MemRelationType.prePost.name);
      expect(entity.toMap['value'], 15);
    });

    test('SavedMemRelationEntityV1 map fallback and toEntityV2', () {
      final createdAt = DateTime(2024, 1, 1);
      final updatedAt = DateTime(2024, 1, 2);
      final archivedAt = DateTime(2024, 1, 3);
      final saved = SavedMemRelationEntityV1({
        'id': 9,
        'source_mems_id': 10,
        'target_mems_id': 11,
        'type': MemRelationType.prePost.name,
        'value': 12,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      });

      expect(saved.value.sourceMemId, 10);
      expect(saved.value.targetMemId, 11);
      expect(saved.value.value, 12);
      expect(saved.toEntityV2().id, 9);
      expect(saved.toEntityV2().sourceMemId, 10);
      expect(saved.toEntityV2().targetMemId, 11);
    });

    test('fromEntityV2 and fromTuple', () {
      final now = DateTime(2024, 2, 1);
      final saved = SavedMemRelationEntityV1.fromEntityV2(
        MemRelationEntity(
          20,
          21,
          MemRelationType.prePost,
          30,
          3,
          now,
          now,
          null,
        ),
      );
      expect(saved.id, 3);
      expect(saved.value.sourceMemId, 20);

      final fromTuple = MemRelationEntity.fromTuple(
        _FakeRow(
          id: 4,
          sourceMemId: 31,
          targetMemId: 32,
          type: MemRelationType.prePost.name,
          value: 33,
          createdAt: now,
          updatedAt: now,
          archivedAt: null,
        ),
      );
      expect(fromTuple.id, 4);
      expect(fromTuple.type, MemRelationType.prePost);
      expect(fromTuple.value, 33);
    });

    test('insertable and updateable convert fields', () {
      final insertable = convertIntoMemRelationsInsertable(
        MemRelation.by(1, 2, MemRelationType.prePost, 3),
      );
      expect(insertable.sourceMemId.value, 1);
      expect(insertable.targetMemId.value, 2);
      expect(insertable.type.value, MemRelationType.prePost.name);
      expect(insertable.value.value, 3);
      expect(insertable.createdAt.value, isNotNull);

      final updateable = convertIntoMemRelationsUpdateable(
        MemRelationEntity(
          null,
          null,
          MemRelationType.prePost,
          5,
          6,
          DateTime(2024, 3, 1),
          null,
          DateTime(2024, 3, 2),
        ),
      );
      expect(updateable.sourceMemId.value, 0);
      expect(updateable.targetMemId.value, 0);
      expect(updateable.type.value, MemRelationType.prePost.name);
      expect(updateable.value.value, 5);
      expect(updateable.archivedAt.value, DateTime(2024, 3, 2));
      expect(updateable.updatedAt.value, isNotNull);
    });
  });
}

class _FakeRow {
  final int id;
  final int sourceMemId;
  final int targetMemId;
  final String type;
  final int value;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  _FakeRow({
    required this.id,
    required this.sourceMemId,
    required this.targetMemId,
    required this.type,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });
}
