import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem;
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_repository.dart';
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
}
