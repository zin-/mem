import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide MemItem;
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  late AppDatabase db;
  late MemItemRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
    repository = MemItemRepository();
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<MemItemRepository>();
  });

  Future<int> createMem(String name) async {
    final row = await db.into(db.mems).insertReturning(
          MemsCompanion.insert(
            name: name,
            createdAt: DateTime(2024, 1, 1),
          ),
        );
    return row.id;
  }

  test('ship returns empty when there is no record', () async {
    final items = await repository.ship();
    expect(items, isEmpty);
  });

  test('receive and ship by memId', () async {
    final mem1 = await createMem('m1');
    final mem2 = await createMem('m2');
    await repository.receive(MemItem(mem1, MemItemType.memo, 'a'));
    await repository.receive(MemItem(mem2, MemItemType.memo, 'b'));

    final mem1Items = await repository.ship(memId: mem1);
    expect(mem1Items.length, 1);
    expect(mem1Items.single.memId, mem1);
    expect(mem1Items.single.value, 'a');
  });

  test('replace updates value', () async {
    final memId = await createMem('m');
    final saved = await repository.receive(MemItem(memId, MemItemType.memo, 'a'));

    final replaced = await repository.replace(
      MemItemEntity(
        saved.memId,
        saved.type,
        'updated',
        saved.id,
        saved.createdAt,
        saved.updatedAt,
        saved.archivedAt,
      ),
    );

    expect(replaced.value, 'updated');
    expect(replaced.updatedAt, isNotNull);
  });

  test('archiveBy and unarchiveBy update archivedAt', () async {
    final memId = await createMem('m');
    await repository.receive(MemItem(memId, MemItemType.memo, 'x'));
    final archivedAt = DateTime(2024, 1, 2);
    final archived = await repository.archiveBy(memId: memId, archivedAt: archivedAt);
    expect(archived.single.archivedAt, archivedAt);

    final updatedAt = DateTime(2024, 1, 3);
    final unarchived = await repository.unarchiveBy(memId: memId, updatedAt: updatedAt);
    expect(unarchived.single.archivedAt, isNull);
    expect(unarchived.single.updatedAt, isNotNull);
  });
}
