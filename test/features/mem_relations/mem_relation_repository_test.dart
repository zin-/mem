import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide MemRelation;
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  late AppDatabase db;
  late MemRelationRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
    repository = MemRelationRepository();
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<MemRelationRepository>();
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

  test('shipBySourceMemId returns empty when sourceMemId is null', () async {
    final rows = await repository.shipBySourceMemId(null);
    expect(rows, isEmpty);
  });

  test('receive, shipBySourceMemId and replace', () async {
    final source = await createMem('s');
    final target = await createMem('t');
    final received = await repository.receive(
      MemRelation.by(source, target, MemRelationType.prePost, 10),
    );
    expect(received.value, 10);

    final bySource = await repository.shipBySourceMemId(source);
    expect(bySource.length, 1);
    expect(bySource.single.targetMemId, target);

    final replaced = await repository.replace(
      MemRelationEntity(
        bySource.single.sourceMemId,
        bySource.single.targetMemId,
        bySource.single.type,
        20,
        bySource.single.id,
        bySource.single.createdAt,
        bySource.single.updatedAt,
        bySource.single.archivedAt,
      ),
    );
    expect(replaced.value, 20);
  });

  test('archiveBy and unarchiveBy by related/source/target ids', () async {
    final source = await createMem('s');
    final target = await createMem('t');
    final other = await createMem('o');
    await repository.receive(MemRelation.by(source, target, MemRelationType.prePost, 1));
    await repository.receive(MemRelation.by(other, target, MemRelationType.prePost, 2));

    final archivedAt = DateTime(2024, 1, 2);
    final archived = await repository.archiveBy(
      relatedMemId: target,
      archivedAt: archivedAt,
    );
    expect(archived, hasLength(2));
    expect(archived.every((e) => e.archivedAt == archivedAt), isTrue);

    final unarchivedByRelated = await repository.unarchiveBy(relatedMemId: target);
    expect(unarchivedByRelated, hasLength(2));
    expect(unarchivedByRelated.every((e) => e.archivedAt == null), isTrue);

    final unarchivedBySourceTarget =
        await repository.unarchiveBy(sourceMemId: source, targetMemId: target);
    expect(unarchivedBySourceTarget, hasLength(1));
    expect(unarchivedBySourceTarget.single.sourceMemId, source);
    expect(unarchivedBySourceTarget.single.targetMemId, target);
  });

  test('waste deletes by sourceMemId or all', () async {
    final source = await createMem('s');
    final target = await createMem('t');
    await repository.receive(MemRelation.by(source, target, MemRelationType.prePost, 1));
    await repository.receive(MemRelation.by(source, target, MemRelationType.prePost, 2));

    final deletedBySource = await repository.waste(sourceMemId: source);
    expect(deletedBySource, hasLength(2));

    await repository.receive(MemRelation.by(source, target, MemRelationType.prePost, 3));
    final deletedAll = await repository.waste();
    expect(deletedAll, hasLength(1));
  });
}
