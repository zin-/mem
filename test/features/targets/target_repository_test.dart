import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Target;
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  late AppDatabase db;
  late TargetRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(db),
    );
    repository = TargetRepository();
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<TargetRepository>();
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

  Target buildTarget(int? memId, {TargetType type = TargetType.equalTo}) => Target(
        memId: memId,
        targetType: type,
        targetUnit: TargetUnit.count,
        value: 10,
        period: Period.aDay,
      );

  test('receive and ship by memId/memIds', () async {
    final mem1 = await createMem('m1');
    final mem2 = await createMem('m2');

    await repository.receive(buildTarget(mem1));
    await repository.receive(buildTarget(mem2, type: TargetType.moreThan));

    final byMemId = await repository.shipByMemId(mem1);
    expect(byMemId, hasLength(1));
    expect(byMemId.single.memId, mem1);

    final byMemIds = await repository.shipByMemIds([mem2]);
    expect(byMemIds, hasLength(1));
    expect(byMemIds.single.memId, mem2);
    expect(byMemIds.single.targetType, TargetType.moreThan);
  });

  test('shipByMemIds returns empty for empty input', () async {
    final targets = await repository.shipByMemIds([]);
    expect(targets, isEmpty);
  });

  test('replace updates target and waste deletes', () async {
    final memId = await createMem('m');
    final created = await repository.receive(buildTarget(memId));

    final replaced = await repository.replace(
      TargetEntity(
        created.memId,
        TargetType.lessThan,
        TargetUnit.time,
        120,
        Period.aWeek,
        created.id,
        created.createdAt,
        created.updatedAt,
        created.archivedAt,
      ),
    );
    expect(replaced.targetType, TargetType.lessThan);
    expect(replaced.targetUnit, TargetUnit.time);
    expect(replaced.period, Period.aWeek);

    final deletedByMem = await repository.waste(memId: memId);
    expect(deletedByMem, hasLength(1));

    await repository.receive(buildTarget(memId));
    final deletedAll = await repository.waste();
    expect(deletedAll, hasLength(1));
  });
}
