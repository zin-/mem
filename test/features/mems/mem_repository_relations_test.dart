import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem, MemRelation;
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

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

  Future<List<MemRelationEntity>> storedRelations(int memId) async =>
      (await repository.shipById(memId)).memRelations!;

  group('MemRepository relations', () {
    test('ship attaches source relations and leaves others empty', () async {
      final source = await repository.receive(Mem(null, 'source', null, null));
      final target = await repository.receive(Mem(null, 'target', null, null));
      final other = await repository.receive(Mem(null, 'other', null, null));
      final none = await repository.receive(Mem(null, 'none', null, null));
      expect(source.memRelations, isNull);

      await repository.receiveRelation(
        MemRelation.by(source.id, target.id, MemRelationType.prePost, 10),
      );
      await repository.receiveRelation(
        MemRelation.by(other.id, target.id, MemRelationType.prePost, 20),
      );

      final replaced = await repository.replace(
        source.updatedWith(
          update: (mem) => Mem(mem.id, 'renamed', mem.doneAt, mem.period),
        ),
      );
      expect(replaced.memRelations, isNull);
      expect(replaced.name, 'renamed');

      final all = await repository.ship(loadLatestAct: true);
      final loadedSource = all.singleWhere((mem) => mem.id == source.id);
      expect(loadedSource.memRelations, hasLength(1));
      expect(loadedSource.memRelations!.single.targetMemId, target.id);
      expect(loadedSource.memRelations!.single.value, 10);
      expect(
        all.singleWhere((mem) => mem.id == target.id).memRelations,
        isEmpty,
      );
      expect(
        all.singleWhere((mem) => mem.id == other.id).memRelations!.single.value,
        20,
      );
      expect(
        all.singleWhere((mem) => mem.id == none.id).memRelations,
        isEmpty,
      );

      final onlySource = await repository.ship(id: source.id);
      expect(onlySource.single.memRelations, hasLength(1));
      expect(onlySource.single.memRelations!.single.sourceMemId, source.id);
    });

    test('replace updates row and waste filters by sourceMemId', () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      final other = await repository.receive(Mem(null, 'o', null, null));
      final created = await repository.receiveRelation(
        MemRelation.by(source.id, target.id, MemRelationType.prePost, 10),
      );
      await repository.receiveRelation(
        MemRelation.by(source.id, target.id, MemRelationType.prePost, 11),
      );
      await repository.receiveRelation(
        MemRelation.by(other.id, target.id, MemRelationType.prePost, 12),
      );

      final replaced = await repository.replaceRelation(
        MemRelationEntity(
          created.sourceMemId,
          created.targetMemId,
          created.type,
          20,
          created.id,
          created.createdAt,
          created.updatedAt,
          created.archivedAt,
        ),
      );

      expect(replaced.value, 20);
      expect(replaced.id, created.id);
      expect(replaced.updatedAt, isNotNull);

      final deletedBySource = await repository.wasteRelations(
        sourceMemId: source.id,
      );
      expect(deletedBySource, hasLength(2));
      expect(await storedRelations(source.id), isEmpty);
      expect((await storedRelations(other.id)).single.value, 12);

      final deletedAll = await repository.wasteRelations();
      expect(deletedAll, hasLength(1));
      expect(await storedRelations(other.id), isEmpty);
    });

    test('archiveRelations and unarchiveRelations by related source target',
        () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      final other = await repository.receive(Mem(null, 'o', null, null));
      await repository.receiveRelation(
        MemRelation.by(source.id, target.id, MemRelationType.prePost, 1),
      );
      await repository.receiveRelation(
        MemRelation.by(other.id, target.id, MemRelationType.prePost, 2),
      );

      final archivedAt = DateTime(2024, 1, 2);
      final archived = await repository.archiveRelations(
        relatedMemId: target.id,
        archivedAt: archivedAt,
      );
      expect(archived, hasLength(2));
      expect(archived.every((e) => e.archivedAt == archivedAt), isTrue);

      final unarchivedByRelated = await repository.unarchiveRelations(
        relatedMemId: target.id,
      );
      expect(unarchivedByRelated, hasLength(2));
      expect(unarchivedByRelated.every((e) => e.archivedAt == null), isTrue);

      final unarchivedBySourceTarget = await repository.unarchiveRelations(
        sourceMemId: source.id,
        targetMemId: target.id,
      );
      expect(unarchivedBySourceTarget, hasLength(1));
      expect(unarchivedBySourceTarget.single.sourceMemId, source.id);
      expect(unarchivedBySourceTarget.single.targetMemId, target.id);
    });
  });

  group('MemService.save relations', () {
    test('new mem returns inserted relation', () async {
      final target = await repository.receive(Mem(null, 't', null, null));

      final (_, _, _, savedRelations, savedMem) = await MemService().save((
        MemViewData(Mem(null, 'new', null, null)),
        [],
        [],
        null,
        [
          MemRelationEntityV1.by(
            null,
            target.id,
            MemRelationType.prePost,
            10,
          ),
        ],
      ));

      expect(savedRelations, hasLength(1));
      expect(savedRelations!.single.value.sourceMemId, savedMem.id);
      expect(savedRelations.single.value.targetMemId, target.id);
      expect(savedRelations.single.value.value, 10);
      expect(savedMem.memRelations, isNull);

      final stored = await storedRelations(savedMem.id);
      expect(stored, hasLength(1));
      expect(stored.single.value, 10);
    });

    test('saved relation is updated in place', () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      final relation = await repository.receiveRelation(
        MemRelation.by(source.id, target.id, MemRelationType.prePost, 10),
      );
      final edited =
          SavedMemRelationEntityV1.fromEntityV2(relation).updatedWith(
        (v) => MemRelation.by(v.sourceMemId, v.targetMemId, v.type, 30),
      );

      final (_, _, _, savedRelations, savedMem) = await MemService().save((
        MemViewData.fromEntityV2(source),
        [],
        [],
        null,
        [edited],
      ));

      expect(
          (savedRelations!.single as SavedMemRelationEntityV1).id, relation.id);
      expect(savedRelations.single.value.value, 30);
      expect(savedMem.memRelations, isNull);

      final stored = await storedRelations(source.id);
      expect(stored, hasLength(1));
      expect(stored.single.id, relation.id);
      expect(stored.single.value, 30);
    });

    test('empty list deletes relations of the source', () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      final other = await repository.receive(Mem(null, 'o', null, null));
      await repository.receiveRelation(
        MemRelation.by(source.id, target.id, MemRelationType.prePost, 1),
      );
      await repository.receiveRelation(
        MemRelation.by(other.id, target.id, MemRelationType.prePost, 2),
      );

      final (_, _, _, savedRelations, _) = await MemService().save((
        MemViewData.fromEntityV2(source),
        [],
        [],
        null,
        <MemRelationEntityV1>[],
      ));

      expect(savedRelations, isEmpty);
      expect(await storedRelations(source.id), isEmpty);
      expect((await storedRelations(other.id)).single.value, 2);
    });

    test('null leaves existing relations', () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      final relation = await repository.receiveRelation(
        MemRelation.by(source.id, target.id, MemRelationType.prePost, 5),
      );

      final (_, _, _, savedRelations, _) = await MemService().save((
        MemViewData.fromEntityV2(source),
        [],
        [],
        null,
        null,
      ));

      expect(savedRelations, isEmpty);
      final stored = await storedRelations(source.id);
      expect(stored, hasLength(1));
      expect(stored.single.id, relation.id);
      expect(stored.single.value, 5);
    });
  });

  group('MemService archive relations', () {
    test('shipById after archive includes the archived source relation',
        () async {
      final source = await repository.receive(Mem(null, 's', null, null));
      final target = await repository.receive(Mem(null, 't', null, null));
      await repository.receiveRelation(
        MemRelation.by(source.id, target.id, MemRelationType.prePost, 7),
      );

      final archived = await MemService().archive(source);

      expect(archived.memRelations, hasLength(1));
      expect(archived.memRelations!.single.archivedAt, isNotNull);
      expect(archived.memRelations!.single.value, 7);

      final unarchived = await MemService().unarchive(archived);
      expect(unarchived.memRelations, hasLength(1));
      expect(unarchived.memRelations!.single.archivedAt, isNull);
      expect(unarchived.memRelations!.single.value, 7);
    });
  });
}
