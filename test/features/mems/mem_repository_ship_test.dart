import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem, Target;
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  late MemRepository repository;

  setUp(() {
    Singleton.override<DriftDatabaseAccessor>(
      DriftDatabaseAccessor.withDatabase(AppDatabase.memory()),
    );
    Singleton.reset<MemRepository>();
    repository = MemRepository();
  });

  tearDown(() async {
    await DriftRepository.close();
    Singleton.reset<MemRepository>();
    Singleton.reset<TargetRepository>();
  });

  test('ship filters archived and done, and applies limit and offset',
      () async {
    await repository.receive(Mem(null, 'active', null, null));
    final toArchive =
        await repository.receive(Mem(null, 'archived', null, null));
    await repository.replace(
      toArchive.updatedWith(archivedAt: () => DateTime(2024, 1, 1)),
    );
    await repository.receive(Mem(null, 'done', DateTime(2024, 2, 1), null));

    expect(
      (await repository.ship(archived: true)).map((mem) => mem.name),
      ['archived'],
    );
    expect(
      (await repository.ship(done: true)).map((mem) => mem.name),
      ['done'],
    );
    expect(await repository.ship(id: -1), isEmpty);
    expect(await repository.ship(limit: 1), hasLength(1));
    expect(await repository.ship(offset: 2), hasLength(1));
    expect(await repository.ship(limit: 1, offset: 1), hasLength(1));
  });

  test('ship attaches each mem target and leaves others null', () async {
    final withTarget = await repository.receive(Mem(null, 'with', null, null));
    final withoutTarget =
        await repository.receive(Mem(null, 'without', null, null));
    await TargetRepository().receive(
      Target(
        memId: withTarget.id,
        targetType: TargetType.moreThan,
        targetUnit: TargetUnit.count,
        value: 3,
        period: Period.aWeek,
      ),
    );

    final all = await repository.ship();
    final loaded = all.singleWhere((mem) => mem.id == withTarget.id);
    expect(loaded.target?.memId, withTarget.id);
    expect(loaded.target?.targetType, TargetType.moreThan);
    expect(loaded.target?.targetUnit, TargetUnit.count);
    expect(loaded.target?.value, 3);
    expect(loaded.target?.period, Period.aWeek);
    expect(
      all.singleWhere((mem) => mem.id == withoutTarget.id).target,
      isNull,
    );

    final byId = await repository.shipById(withTarget.id);
    expect(byId.target?.value, 3);
    expect(byId.target?.memId, withTarget.id);
    expect((await repository.shipById(withoutTarget.id)).target, isNull);
  });
}
