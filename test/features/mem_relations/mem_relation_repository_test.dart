import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem, MemRelation;
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  late MemRelationRepository repository;

  setUp(() {
    final db = AppDatabase.memory();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
    Singleton.reset<MemRepository>();
    Singleton.reset<MemRelationRepository>();
    repository = MemRelationRepository();
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<MemRepository>();
    Singleton.reset<MemRelationRepository>();
  });

  test('shipBySourceMemId returns empty when sourceMemId is null', () async {
    final rows = await repository.shipBySourceMemId(null);
    expect(rows, isEmpty);
  });

  test('shipBySourceMemId returns relations for the source', () async {
    final source =
        (await MemRepository().receive(Mem(null, 's', null, null))).id;
    final target =
        (await MemRepository().receive(Mem(null, 't', null, null))).id;
    final other =
        (await MemRepository().receive(Mem(null, 'o', null, null))).id;
    await MemRepository().receiveRelation(
      MemRelation.by(source, target, MemRelationType.prePost, 10),
    );
    await MemRepository().receiveRelation(
      MemRelation.by(other, target, MemRelationType.prePost, 20),
    );

    final bySource = await repository.shipBySourceMemId(source);
    expect(bySource, hasLength(1));
    expect(bySource.single.sourceMemId, source);
    expect(bySource.single.targetMemId, target);
    expect(bySource.single.value, 10);
  });
}
