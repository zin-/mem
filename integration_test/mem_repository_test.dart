import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/logger.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/mem.dart';

void main() async {
  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late final Database database;
  late final MemRepository memRepository;

  setUpAll(() async {
    database = await DatabaseManager().open(DefD('test_mem.db', 1, [memTable]));
    memRepository = MemRepository.initialize(database.getTable(memTable.name));
  });
  setUp(() async {
    await memRepository.discardAll();
  });

  group('MemRepository', () {
    test(
      'new before initialize',
      () {
        expect(
          MemRepository(),
          throwsA(((e) => e is RepositoryException)),
        );
      },
      // FIXME factory内のテストはできない？
      skip: true,
    );

    test(
      'receive',
      () async {
        const memName = 'test mem name';
        final memMap = <String, dynamic>{'name': memName};

        final receivedMem = await memRepository.receive(memMap);

        expect(receivedMem.name, memName);
        expect(receivedMem.createdAt, const TypeMatcher<DateTime>());
        expect(receivedMem.updatedAt, null);
        expect(receivedMem.archivedAt, null);
      },
    );

    test(
      'shipAll',
      () async {
        const memName1 = 'test mem name 1';
        final memMap = <String, dynamic>{'name': memName1};
        final receivedMem1 = await memRepository.receive(memMap);
        const memName2 = 'test mem name 2';
        final memMap2 = <String, dynamic>{'name': memName2};
        final receivedMem2 = await memRepository.receive(memMap2);

        final selectedMemList = await memRepository.ship(false);

        expect(selectedMemList.length, 2);
        expect(
          selectedMemList.map((mem) => mem.toMap()),
          [receivedMem1.toMap(), receivedMem2.toMap()],
        );
      },
    );

    test(
      'shipWhereIdIs',
      () async {
        const memName1 = 'test mem name 1';
        final memMap = <String, dynamic>{'name': memName1};
        final receivedMem1 = await memRepository.receive(memMap);
        const memName2 = 'test mem name 2';
        final memMap2 = <String, dynamic>{'name': memName2};
        await memRepository.receive(memMap2);

        final selectedMem = await memRepository.shipWhereIdIs(receivedMem1.id);

        expect(selectedMem.toMap(), receivedMem1.toMap());
      },
    );

    test(
      'update',
      () async {
        const memName1 = 'test mem name 1';
        final memMap = <String, dynamic>{'name': memName1};
        final receivedMem1 = await memRepository.receive(memMap);
        const memName2 = 'test mem name 2';
        final memMap2 = <String, dynamic>{'name': memName2};
        await memRepository.receive(memMap2);

        final map = receivedMem1.toMap();
        const updateMemName = 'update mem name';

        final updatedMem = await memRepository.update(
          Mem.fromMap(map..['name'] = updateMemName),
        );

        expect(updatedMem.id, receivedMem1.id);
        expect(updatedMem.name, updateMemName);
        expect(updatedMem.createdAt, const TypeMatcher<DateTime>());
        expect(updatedMem.updatedAt, const TypeMatcher<DateTime>());
        expect(
          updatedMem.updatedAt?.millisecondsSinceEpoch,
          greaterThan(updatedMem.createdAt.millisecondsSinceEpoch),
        );
        expect(updatedMem.archivedAt, null);

        final selectedByIdUpdatedMem =
            await memRepository.shipWhereIdIs(receivedMem1.id);
        expect(selectedByIdUpdatedMem.toMap(), updatedMem.toMap());
      },
    );

    test(
      'discardWhereIdIs',
      () async {
        const memName1 = 'test mem name 1';
        final memMap = <String, dynamic>{'name': memName1};
        final receivedMem1 = await memRepository.receive(memMap);
        const memName2 = 'test mem name 2';
        final memMap2 = <String, dynamic>{'name': memName2};
        final receivedMem2 = await memRepository.receive(memMap2);

        final removeResult =
            await memRepository.discardWhereIdIs(receivedMem1.id);
        expect(removeResult, true);

        final selectedMemList = await memRepository.ship(false);
        expect(selectedMemList.length, 1);
        expect(
            selectedMemList.map((mem) => mem.toMap()), [receivedMem2.toMap()]);
      },
    );

    test(
      'discardAll',
      () async {
        final memMap = <String, dynamic>{'name': 'test mem name'};
        await memRepository.receive(memMap);
        await memRepository.receive(memMap);

        final removedCount = await memRepository.discardAll();

        expect(removedCount, 2);

        final selected = await memRepository.ship(false);
        expect(selected.length, 0);
      },
    );
  });
}
