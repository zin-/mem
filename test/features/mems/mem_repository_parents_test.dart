import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem, MemParent;
import 'package:mem/features/mem_parents/mem_parent.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_repository.dart';
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

  test('child keeps one parent and cutting deletes the row', () async {
    final child = await repository.receive(Mem(null, 'child', null, null));
    final parent = await repository.receive(Mem(null, 'parent', null, null));
    final other = await repository.receive(Mem(null, 'other', null, null));

    final saved = await repository.receiveParent(
      MemParent(memId: child.id, parentMemId: parent.id),
    );

    expect(saved.memId, child.id);
    expect(saved.parentMemId, parent.id);
    expect(
      (await repository.shipParentByMemId(child.id))?.parentMemId,
      parent.id,
    );
    expect(
      (await repository.shipChildrenByParentMemId(parent.id))
          .map((e) => e.memId),
      [child.id],
    );
    expect(await repository.shipParentByMemId(parent.id), isNull);

    await expectLater(
      repository.receiveParent(
        MemParent(memId: child.id, parentMemId: other.id),
      ),
      throwsA(anything),
    );
    expect(
      (await repository.shipParentByMemId(child.id))?.parentMemId,
      parent.id,
    );

    final wasted = await repository.wasteParents(memId: child.id);
    expect(wasted.single.memId, child.id);
    expect(await repository.shipParentByMemId(child.id), isNull);
    expect(await repository.shipChildrenByParentMemId(parent.id), isEmpty);
  });

  test('a mem cannot be its own parent or an ancestor of itself', () async {
    final mem = await repository.receive(Mem(null, 'mem', null, null));
    final mid = await repository.receive(Mem(null, 'mid', null, null));

    await expectLater(
      repository.receiveParent(MemParent(memId: mem.id, parentMemId: mem.id)),
      throwsA(isA<ArgumentError>()),
    );

    await repository.receiveParent(
      MemParent(memId: mid.id, parentMemId: mem.id),
    );
    await expectLater(
      repository.receiveParent(MemParent(memId: mem.id, parentMemId: mid.id)),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('replaceParent writes another parent and drops the old row', () async {
    final child = await repository.receive(Mem(null, 'child', null, null));
    final parent = await repository.receive(Mem(null, 'parent', null, null));
    final other = await repository.receive(Mem(null, 'other', null, null));
    await repository.receiveParent(
      MemParent(memId: child.id, parentMemId: parent.id),
    );

    final replaced = await repository.replaceParent(
      MemParent(memId: child.id, parentMemId: other.id),
    );

    expect(replaced.memId, child.id);
    expect(replaced.parentMemId, other.id);
    expect(
      (await repository.shipParentByMemId(child.id))?.parentMemId,
      other.id,
    );
    expect(await repository.shipChildrenByParentMemId(parent.id), isEmpty);
    expect(
      (await repository.shipChildrenByParentMemId(other.id))
          .map((e) => e.memId),
      [child.id],
    );
    expect(await db.select(db.memParents).get(), hasLength(1));
  });

  test('replaceParent rejects a cycle and keeps the old parent', () async {
    final child = await repository.receive(Mem(null, 'child', null, null));
    final mid = await repository.receive(Mem(null, 'mid', null, null));
    final top = await repository.receive(Mem(null, 'top', null, null));
    await repository.receiveParent(
      MemParent(memId: child.id, parentMemId: mid.id),
    );
    await repository.receiveParent(
      MemParent(memId: mid.id, parentMemId: top.id),
    );

    await expectLater(
      repository.replaceParent(
        MemParent(memId: mid.id, parentMemId: child.id),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      (await repository.shipParentByMemId(mid.id))?.parentMemId,
      top.id,
    );
    expect(
      (await repository.shipParentByMemId(child.id))?.parentMemId,
      mid.id,
    );
  });

  test('removing a mem removes parent rows that point at it', () async {
    final child = await repository.receive(Mem(null, 'child', null, null));
    final parent = await repository.receive(Mem(null, 'parent', null, null));
    final grand = await repository.receive(Mem(null, 'grand', null, null));
    await repository.receiveParent(
      MemParent(memId: child.id, parentMemId: parent.id),
    );
    await repository.receiveParent(
      MemParent(memId: parent.id, parentMemId: grand.id),
    );

    await repository.waste(id: parent.id);

    expect(await db.select(db.memParents).get(), isEmpty);
  });

  test(
    'shipParentMemIdsWithOpenChildren returns parents of open direct children',
    () async {
      expect(await repository.shipParentMemIdsWithOpenChildren(), isEmpty);

      final withOpenChild =
          await repository.receive(Mem(null, 'with open child', null, null));
      final openChild = await repository.receive(Mem(null, 'open', null, null));
      final doneSibling = await repository.receive(
        Mem(null, 'done sibling', DateTime(2024, 2, 1), null),
      );
      await repository.receiveParent(
        MemParent(memId: openChild.id, parentMemId: withOpenChild.id),
      );
      await repository.receiveParent(
        MemParent(memId: doneSibling.id, parentMemId: withOpenChild.id),
      );

      final withDoneChild =
          await repository.receive(Mem(null, 'with done child', null, null));
      final doneChild = await repository.receive(
        Mem(null, 'done', DateTime(2024, 3, 1), null),
      );
      await repository.receiveParent(
        MemParent(memId: doneChild.id, parentMemId: withDoneChild.id),
      );

      final withArchivedChild = await repository.receive(
        Mem(null, 'with archived child', null, null),
      );
      final archivedChild =
          await repository.receive(Mem(null, 'archived', null, null));
      await repository.replace(
        archivedChild.updatedWith(archivedAt: () => DateTime(2024, 1, 1)),
      );
      await repository.receiveParent(
        MemParent(memId: archivedChild.id, parentMemId: withArchivedChild.id),
      );

      await repository.receive(Mem(null, 'childless', null, null));

      final grand = await repository.receive(Mem(null, 'grand', null, null));
      final doneMid = await repository.receive(
        Mem(null, 'done mid', DateTime(2024, 4, 1), null),
      );
      final grandchild =
          await repository.receive(Mem(null, 'grandchild', null, null));
      await repository.receiveParent(
        MemParent(memId: doneMid.id, parentMemId: grand.id),
      );
      await repository.receiveParent(
        MemParent(memId: grandchild.id, parentMemId: doneMid.id),
      );

      expect(
        await repository.shipParentMemIdsWithOpenChildren(),
        {withOpenChild.id, doneMid.id},
      );
    },
  );
}
