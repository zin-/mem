import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';

void main() {
  group('MemItemEntity', () {
    test('SavedMemItemEntityV1 map fallback and toEntityV2', () {
      final createdAt = DateTime(2024, 1, 1);
      final updatedAt = DateTime(2024, 1, 2);
      final archivedAt = DateTime(2024, 1, 3);
      final saved = SavedMemItemEntityV1({
        'id': 1,
        'mems_id': 10,
        'type': MemItemType.memo.name,
        'value': 'hello',
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      });

      expect(saved.value.memId, 10);
      expect(saved.value.type, MemItemType.memo);
      expect(saved.value.value, 'hello');
      expect(saved.toMap, containsPair('memId', 10));
      expect(saved.toMap, containsPair('type', MemItemType.memo.name));
      expect(saved.toMap, containsPair('value', 'hello'));
      expect(saved.toEntityV2().id, 1);
      expect(saved.toEntityV2().memId, 10);
    });

    test('fromEntityV2 and updatedWith keep base columns', () {
      final createdAt = DateTime(2024, 2, 1);
      final updatedAt = DateTime(2024, 2, 2);
      final archivedAt = DateTime(2024, 2, 3);
      final saved = SavedMemItemEntityV1.fromEntityV2(
        MemItemEntity(
          2,
          MemItemType.memo,
          'before',
          99,
          createdAt,
          updatedAt,
          archivedAt,
        ),
      );

      final updated = saved.updatedWith((v) => MemItem(v.memId, v.type, 'after'));

      expect(updated.id, 99);
      expect(updated.createdAt, createdAt);
      expect(updated.updatedAt, updatedAt);
      expect(updated.archivedAt, archivedAt);
      expect(updated.value.value, 'after');
    });

    test('MemItemEntity fromTuple and insertable/updateable', () {
      final now = DateTime(2024, 3, 1);
      final entity = MemItemEntity.fromTuple(
        _FakeRow(
          id: 7,
          memId: 8,
          type: MemItemType.memo.name,
          value: 'tuple',
          createdAt: now,
          updatedAt: now,
          archivedAt: null,
        ),
      );

      expect(entity.id, 7);
      expect(entity.memId, 8);
      expect(entity.type, MemItemType.memo);
      expect(entity.value, 'tuple');

      final insertable = convertIntoMemItemsInsertable(
        MemItem(null, MemItemType.memo, 'ins'),
        now,
      );
      expect(insertable.memId.value, 0);
      expect(insertable.type.value, MemItemType.memo.name);
      expect(insertable.value.value, 'ins');
      expect(insertable.createdAt.value, now);

      final updateable = convertIntoMemItemsUpdateable(
        MemItemEntity(5, MemItemType.memo, 'upd', 1, now, null, now),
      );
      expect(updateable.memId.value, 5);
      expect(updateable.type.value, MemItemType.memo.name);
      expect(updateable.value.value, 'upd');
      expect(updateable.archivedAt.value, now);
      expect(updateable.updatedAt.value, isNotNull);
    });
  });
}

class _FakeRow {
  final int id;
  final int memId;
  final String type;
  final String value;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  _FakeRow({
    required this.id,
    required this.memId,
    required this.type,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });
}
