import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem, MemPrePost;
import 'package:mem/features/mem_preposts/mem_prepost.dart';
import 'package:mem/features/mem_preposts/mem_prepost_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

MemPrePost prePost(int sourceMemId, int targetMemId, int minutes) =>
    MemPrePost.of(
      sourceMemId: sourceMemId,
      targetMemId: targetMemId,
      minutes: minutes,
    )!;

void main() {
  late MemRepository repository;

  setUp(() {
    final db = AppDatabase.memory();
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

  Future<List<MemPrePostEntity>> storedPrePosts(int memId) async =>
      (await repository.shipById(memId)).memPrePosts!;

  group('MemRepository preposts', () {
    test('shipPrePostsBySourceMemId returns empty when sourceMemId is null',
        () async {
      expect(await repository.shipPrePostsBySourceMemId(null), isEmpty);
    });

    test('ship attaches source relations and leaves others empty', () async {
      final source = await repository.receive(Mem(null, 'source', null, null));
      final target = await repository.receive(Mem(null, 'target', null, null));
      final other = await repository.receive(Mem(null, 'other', null, null));
      final none = await repository.receive(Mem(null, 'none', null, null));
      expect(source.memPrePosts, isNull);

      await repository.receivePrePost(
        prePost(source.id, target.id, 10),
      );
      await repository.receivePrePost(
        prePost(other.id, target.id, 20),
      );

      final replaced = await repository.replace(
        source.updatedWith(
          update: (mem) => Mem(mem.id, 'renamed', mem.doneAt, mem.period),
        ),
      );
      expect(replaced.memPrePosts, isNull);
      expect(replaced.name, 'renamed');

      final all = await repository.ship(loadLatestAct: true);
      final loadedSource = all.singleWhere((mem) => mem.id == source.id);
      expect(loadedSource.memPrePosts, hasLength(1));
      expect(loadedSource.memPrePosts!.single.targetMemId, target.id);
      expect(loadedSource.memPrePosts!.single.minutes, 10);
      expect(
        all.singleWhere((mem) => mem.id == target.id).memPrePosts,
        isEmpty,
      );
      expect(
        all
            .singleWhere((mem) => mem.id == other.id)
            .memPrePosts!
            .single
            .minutes,
        20,
      );
      expect(
        all.singleWhere((mem) => mem.id == none.id).memPrePosts,
        isEmpty,
      );

      final onlySource = await repository.ship(id: source.id);
      expect(onlySource.single.memPrePosts, hasLength(1));
      expect(onlySource.single.memPrePosts!.single.sourceMemId, source.id);
    });

    test('replace updates row and waste filters by sourceMemId', () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      final other = await repository.receive(Mem(null, 'o', null, null));
      final created = await repository.receivePrePost(
        prePost(source.id, target.id, 10),
      );
      await repository.receivePrePost(
        prePost(source.id, target.id, 11),
      );
      await repository.receivePrePost(
        prePost(other.id, target.id, 12),
      );

      final replaced = await repository.replacePrePost(
        MemPrePostEntity(
          created.sourceMemId,
          created.targetMemId,
          20,
          created.id,
          created.createdAt,
          created.updatedAt,
          created.archivedAt,
        ),
      );

      expect(replaced.minutes, 20);
      expect(replaced.id, created.id);
      expect(replaced.updatedAt, isNotNull);

      final deletedBySource = await repository.wastePrePosts(
        sourceMemId: source.id,
      );
      expect(deletedBySource, hasLength(2));
      expect(await storedPrePosts(source.id), isEmpty);
      expect((await storedPrePosts(other.id)).single.minutes, 12);

      final deletedAll = await repository.wastePrePosts();
      expect(deletedAll, hasLength(1));
      expect(await storedPrePosts(other.id), isEmpty);
    });

    test('archivePrePosts and unarchivePrePosts by related source target',
        () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      final other = await repository.receive(Mem(null, 'o', null, null));
      await repository.receivePrePost(
        prePost(source.id, target.id, 1),
      );
      await repository.receivePrePost(
        prePost(other.id, target.id, 2),
      );

      final archivedAt = DateTime(2024, 1, 2);
      final archived = await repository.archivePrePosts(
        relatedMemId: target.id,
        archivedAt: archivedAt,
      );
      expect(archived, hasLength(2));
      expect(archived.every((e) => e.archivedAt == archivedAt), isTrue);

      final unarchivedByRelated = await repository.unarchivePrePosts(
        relatedMemId: target.id,
      );
      expect(unarchivedByRelated, hasLength(2));
      expect(unarchivedByRelated.every((e) => e.archivedAt == null), isTrue);

      final unarchivedBySourceTarget = await repository.unarchivePrePosts(
        sourceMemId: source.id,
        targetMemId: target.id,
      );
      expect(unarchivedBySourceTarget, hasLength(1));
      expect(unarchivedBySourceTarget.single.sourceMemId, source.id);
      expect(unarchivedBySourceTarget.single.targetMemId, target.id);
    });
  });

  group('MemService.save preposts', () {
    test('new mem returns inserted relation', () async {
      final target = await repository.receive(Mem(null, 't', null, null));

      final (_, _, _, savedRelations, savedMem) = await MemService().save((
        MemViewData(Mem(null, 'new', null, null)),
        [],
        [],
        null,
        [
          MemPrePostEntityV1.by(
            null,
            target.id,
            10,
          ),
        ],
      ));

      expect(savedRelations, hasLength(1));
      expect(savedRelations!.single.value.sourceMemId, savedMem.id);
      expect(savedRelations.single.value.targetMemId, target.id);
      expect(savedRelations.single.value.minutes, 10);
      expect(savedMem.memPrePosts, isNull);

      final stored = await storedPrePosts(savedMem.id);
      expect(stored, hasLength(1));
      expect(stored.single.minutes, 10);
    });

    test('saved relation is updated in place', () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      final relation = await repository.receivePrePost(
        prePost(source.id, target.id, 10),
      );
      final edited = SavedMemPrePostEntityV1.fromEntityV2(relation).updatedWith(
        (v) => MemPrePost.of(
          sourceMemId: v.sourceMemId,
          targetMemId: v.targetMemId,
          minutes: 30,
        )!,
      );

      final (_, _, _, savedRelations, savedMem) = await MemService().save((
        MemViewData.fromEntity(source),
        [],
        [],
        null,
        [edited],
      ));

      expect(
          (savedRelations!.single as SavedMemPrePostEntityV1).id, relation.id);
      expect(savedRelations.single.value.minutes, 30);
      expect(savedMem.memPrePosts, isNull);

      final stored = await storedPrePosts(source.id);
      expect(stored, hasLength(1));
      expect(stored.single.id, relation.id);
      expect(stored.single.minutes, 30);
    });

    test('empty list deletes relations of the source', () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      final other = await repository.receive(Mem(null, 'o', null, null));
      await repository.receivePrePost(
        prePost(source.id, target.id, 1),
      );
      await repository.receivePrePost(
        prePost(other.id, target.id, 2),
      );

      final (_, _, _, savedRelations, _) = await MemService().save((
        MemViewData.fromEntity(source),
        [],
        [],
        null,
        <MemPrePostEntityV1>[],
      ));

      expect(savedRelations, isEmpty);
      expect(await storedPrePosts(source.id), isEmpty);
      expect((await storedPrePosts(other.id)).single.minutes, 2);
    });

    test('null leaves existing relations', () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      final relation = await repository.receivePrePost(
        prePost(source.id, target.id, 5),
      );

      final (_, _, _, savedRelations, _) = await MemService().save((
        MemViewData.fromEntity(source),
        [],
        [],
        null,
        null,
      ));

      expect(savedRelations, isEmpty);
      final stored = await storedPrePosts(source.id);
      expect(stored, hasLength(1));
      expect(stored.single.id, relation.id);
      expect(stored.single.minutes, 5);
    });
  });

  group('MemService archive preposts', () {
    test('shipById after archive includes the archived source relation',
        () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      await repository.receivePrePost(
        prePost(source.id, target.id, 7),
      );

      final archived = await MemService().archive(source);

      expect(archived.memPrePosts, hasLength(1));
      expect(archived.memPrePosts!.single.archivedAt, isNotNull);
      expect(archived.memPrePosts!.single.minutes, 7);

      final unarchived = await MemService().unarchive(archived);
      expect(unarchived.memPrePosts, hasLength(1));
      expect(unarchived.memPrePosts!.single.archivedAt, isNull);
      expect(unarchived.memPrePosts!.single.minutes, 7);
    });
  });
}
