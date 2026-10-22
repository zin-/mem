import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem, MemItem;
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  late AppDatabase db;
  late MemRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
    Singleton.reset<MemRepository>();
    repository = MemRepository();
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<MemRepository>();
  });

  Future<List<MemItemEntity>> storedItems(int memId) async =>
      (await repository.shipById(memId)).items!;

  MemEntity memEntityFrom(
    MemEntity source, {
    String? name,
    List<MemItemEntity>? items,
  }) =>
      MemEntity(
        source.id,
        name ?? source.name,
        source.doneAt,
        source.period,
        items,
        source.createdAt,
        source.updatedAt,
        source.archivedAt,
      );

  group('MemRepository items', () {
    test('ship attaches each mem items and leaves others empty', () async {
      final withItem = await repository.receive(
        Mem(null, 'with', null, null),
        items: [MemItem(999, MemItemType.memo, 'a-item')],
      );
      final withoutItem = await repository.receive(
        Mem(null, 'without', null, null),
      );

      expect(withItem.items, hasLength(1));
      expect(withItem.items!.single.memId, withItem.id);
      expect(withItem.items!.single.value, 'a-item');
      expect(withoutItem.items, isEmpty);

      final all = await repository.ship(loadLatestAct: true);
      expect(
        all.singleWhere((mem) => mem.id == withItem.id).items!.single.value,
        'a-item',
      );
      expect(
        all.singleWhere((mem) => mem.id == withoutItem.id).items,
        isEmpty,
      );

      final onlyWithItem = await repository.ship(id: withItem.id);
      expect(onlyWithItem.single.items!.single.value, 'a-item');
    });

    test('replace updates given items and returns them', () async {
      final created = await repository.receive(
        Mem(null, 'm', null, null),
        items: [MemItem(null, MemItemType.memo, 'old')],
      );
      final item = created.items!.single;

      final replaced = await repository.replace(
        memEntityFrom(
          created,
          items: [
            MemItemEntity(
              created.id,
              item.type,
              'changed',
              item.id,
              item.createdAt,
              item.updatedAt,
              item.archivedAt,
            ),
          ],
        ),
      );

      expect(replaced.items, hasLength(1));
      expect(replaced.items!.single.id, item.id);
      expect(replaced.items!.single.value, 'changed');
      expect(replaced.items!.single.updatedAt, isNotNull);

      final stored = await storedItems(created.id);
      expect(stored, hasLength(1));
      expect(stored.single.value, 'changed');
    });

    test('replace without items leaves stored items unchanged', () async {
      final created = await repository.receive(
        Mem(null, 'm', null, null),
        items: [MemItem(null, MemItemType.memo, 'keep')],
      );

      final replaced = await repository.replace(
        memEntityFrom(created, name: 'renamed'),
      );

      expect(replaced.name, 'renamed');
      expect(replaced.items, isNull);

      final reloaded = await repository.shipById(created.id);
      expect(reloaded.name, 'renamed');
      expect(reloaded.items!.single.value, 'keep');
    });

    test('replace inserts receivingItems and does not drop omitted rows',
        () async {
      final created = await repository.receive(
        Mem(null, 'm', null, null),
        items: [
          MemItem(null, MemItemType.memo, 'first'),
          MemItem(null, MemItemType.memo, 'second'),
        ],
      );
      final first = created.items!.first;

      final replaced = await repository.replace(
        memEntityFrom(
          created,
          items: [
            MemItemEntity(
              created.id,
              first.type,
              'first-edited',
              first.id,
              first.createdAt,
              first.updatedAt,
              first.archivedAt,
            ),
          ],
        ),
        receivingItems: [MemItem(null, MemItemType.memo, 'third')],
      );

      expect(replaced.items!.map((item) => item.value), [
        'first-edited',
        'third',
      ]);
      expect(replaced.items!.last.memId, created.id);

      final stored = await storedItems(created.id);
      expect(stored, hasLength(3));
      expect(
          stored.map((item) => item.value),
          containsAll([
            'first-edited',
            'second',
            'third',
          ]));
    });

    test('archiveItems and unarchiveItems update archivedAt', () async {
      final created = await repository.receive(
        Mem(null, 'm', null, null),
        items: [MemItem(null, MemItemType.memo, 'x')],
      );
      final archivedAt = DateTime(2024, 1, 2);

      await repository.archiveItems(created.id, archivedAt: archivedAt);

      final archived = await storedItems(created.id);
      expect(archived.single.archivedAt, archivedAt);

      await repository.unarchiveItems(created.id);

      final unarchived = await storedItems(created.id);
      expect(unarchived.single.archivedAt, isNull);
      expect(unarchived.single.updatedAt, isNotNull);
    });
  });

  group('MemService.save items', () {
    test('new mem returns inserted items from the repository', () async {
      final (savedItems, _, _, _, savedMem) = await MemService().save((
        MemViewData(Mem(null, 'new', null, null)),
        [MemItemEntityV1(MemItem(null, MemItemType.memo, 'hello'))],
        null,
        null,
        null,
      ));

      expect(savedItems, hasLength(1));
      expect(savedItems.single, isA<SavedMemItemEntityV1>());
      expect(savedItems.single.value.value, 'hello');
      expect(savedItems.single.value.memId, savedMem.id);
      expect(savedMem.items!.single.value, 'hello');

      final reloaded = await repository.shipById(savedMem.id);
      expect(reloaded.items!.single.value, 'hello');
    });

    test('saved item is updated in place', () async {
      final created = await repository.receive(
        Mem(null, 'saved', null, null),
        items: [MemItem(null, MemItemType.memo, 'old')],
      );
      final edited =
          SavedMemItemEntityV1.fromEntityV2(created.items!.single).copiedWith(
        value: () => 'new',
      ) as SavedMemItemEntityV1;

      final (savedItems, _, _, _, savedMem) = await MemService().save((
        MemViewData.fromEntityV2(created),
        [edited],
        null,
        null,
        null,
      ));

      expect(savedItems.single.value.value, 'new');
      expect((savedItems.single as SavedMemItemEntityV1).id, edited.id);
      expect(savedMem.items!.single.id, edited.id);

      final stored = await storedItems(created.id);
      expect(stored, hasLength(1));
      expect(stored.single.value, 'new');
    });

    test('unsaved item on an existing mem is inserted', () async {
      final created = await repository.receive(Mem(null, 'saved', null, null));

      final (savedItems, _, _, _, savedMem) = await MemService().save((
        MemViewData.fromEntityV2(created),
        [MemItemEntityV1(MemItem(null, MemItemType.memo, 'added'))],
        null,
        null,
        null,
      ));

      expect(savedItems.single.value.value, 'added');
      expect(savedItems.single.value.memId, created.id);
      expect(savedMem.items!.single.value, 'added');

      final stored = await storedItems(created.id);
      expect(stored, hasLength(1));
      expect(stored.single.value, 'added');
    });

    test('undo inserts items onto the new mem id', () async {
      final created = await repository.receive(
        Mem(null, 'gone', null, null),
        items: [MemItem(null, MemItemType.memo, 'restored')],
      );
      await repository.waste(id: created.id);

      final (savedItems, _, _, _, savedMem) = await MemService().save(
        (
          MemViewData.fromEntityV2(created),
          [SavedMemItemEntityV1.fromEntityV2(created.items!.single)],
          null,
          null,
          null,
        ),
        undo: true,
      );

      expect(savedMem.id, isNot(created.id));
      expect(savedItems.single.value.memId, savedMem.id);
      expect(savedItems.single.value.value, 'restored');
      expect(
        (savedItems.single as SavedMemItemEntityV1).id,
        isNot(created.items!.single.id),
      );
    });
  });

  group('MemService archive items', () {
    test('archive and unarchive the mem and its items', () async {
      final created = await repository.receive(
        Mem(null, 'm', null, null),
        items: [MemItem(null, MemItemType.memo, 'x')],
      );

      final archived = await MemService().archive(created);

      expect(archived.isArchived, isTrue);
      expect(archived.items!.single.archivedAt, isNotNull);
      expect(archived.items!.single.value, 'x');

      final unarchived = await MemService().unarchive(archived);

      expect(unarchived.archivedAt, isNull);
      expect(unarchived.items!.single.archivedAt, isNull);
      expect(unarchived.items!.single.value, 'x');
    });
  });
}
