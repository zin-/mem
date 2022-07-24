import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_repository.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late final DatabaseV2 databaseV2;
  late final MemRepositoryV2 memRepositoryV2;

  setUpAll(() async {
    databaseV2 =
        await DatabaseManager.open(DefD('test_mem.db', 1, [memTableV2]));
    memRepositoryV2 = MemRepositoryV2(databaseV2.getTable(memTableV2.name));
  });
  tearDown(() async {
    await memRepositoryV2.removeAll();
  });
  tearDownAll(() async {
    await databaseV2.delete();
  });

  test(
    'receive',
    () async {
      const memName = 'test mem name';
      final memMap = <String, dynamic>{'name': memName};

      final receivedMem = await memRepositoryV2.receive(memMap);

      expect(receivedMem.id, 1);
      expect(receivedMem.name, memName);
      expect(receivedMem.createdAt, const TypeMatcher<DateTime>());
      expect(receivedMem.updatedAt, null);
      expect(receivedMem.archivedAt, null);
    },
  );

  test(
    'selectAll',
    () async {
      const memName1 = 'test mem name 1';
      final memMap = <String, dynamic>{'name': memName1};
      final receivedMem1 = await memRepositoryV2.receive(memMap);
      const memName2 = 'test mem name 2';
      final memMap2 = <String, dynamic>{'name': memName2};
      final receivedMem2 = await memRepositoryV2.receive(memMap2);

      final selectedMemList = await memRepositoryV2.selectAll();

      expect(selectedMemList.length, 2);
      expect(
        selectedMemList.map((mem) => mem.toMap()),
        [receivedMem1.toMap(), receivedMem2.toMap()],
      );
    },
  );

  test(
    'selectById',
    () async {
      const memName1 = 'test mem name 1';
      final memMap = <String, dynamic>{'name': memName1};
      final receivedMem1 = await memRepositoryV2.receive(memMap);
      const memName2 = 'test mem name 2';
      final memMap2 = <String, dynamic>{'name': memName2};
      await memRepositoryV2.receive(memMap2);

      final selectedMem = await memRepositoryV2.selectById(receivedMem1.id);

      expect(selectedMem.toMap(), receivedMem1.toMap());
    },
  );

  test(
    'update',
    () async {
      const memName1 = 'test mem name 1';
      final memMap = <String, dynamic>{'name': memName1};
      final receivedMem1 = await memRepositoryV2.receive(memMap);
      const memName2 = 'test mem name 2';
      final memMap2 = <String, dynamic>{'name': memName2};
      await memRepositoryV2.receive(memMap2);

      final map = receivedMem1.toMap();
      const updateMemName = 'update mem name';

      final updatedMem = await memRepositoryV2.update(
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
          await memRepositoryV2.selectById(receivedMem1.id);
      expect(selectedByIdUpdatedMem.toMap(), updatedMem.toMap());
    },
  );

  test(
    'removeById',
    () async {
      const memName1 = 'test mem name 1';
      final memMap = <String, dynamic>{'name': memName1};
      final receivedMem1 = await memRepositoryV2.receive(memMap);
      const memName2 = 'test mem name 2';
      final memMap2 = <String, dynamic>{'name': memName2};
      final receivedMem2 = await memRepositoryV2.receive(memMap2);

      final removeResult = await memRepositoryV2.removeById(receivedMem1.id);
      expect(removeResult, true);

      final selectedMemList = await memRepositoryV2.selectAll();
      expect(selectedMemList.length, 1);
      expect(selectedMemList.map((mem) => mem.toMap()), [receivedMem2.toMap()]);
    },
  );

  test(
    'removeAll',
    () async {
      final memMap = <String, dynamic>{'name': 'test mem name'};
      await memRepositoryV2.receive(memMap);
      await memRepositoryV2.receive(memMap);

      final removedCount = await memRepositoryV2.removeAll();

      expect(removedCount, 2);

      final selected = await memRepositoryV2.selectAll();
      expect(selected.length, 0);
    },
  );
}
