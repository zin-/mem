import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_repository.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late final Database database;
  late final MemRepository memRepository;

  setUpAll(() async {
    database = await DatabaseFactory.open('test_mems.db', 1, [memTable]);
    memRepository = MemRepository(database);
  });
  tearDown(() async {
    await memRepository.removeAll();
  });
  tearDownAll(() async {
    database.delete();
  });

  test(
    'receive',
    () async {
      const memName = 'test mem name';
      final memMap = <String, dynamic>{'name': memName};

      final receivedMem = await memRepository.receive(memMap);

      expect(receivedMem.id, 1);
      expect(receivedMem.name, memName);
      expect(receivedMem.createdAt, const TypeMatcher<DateTime>());
      expect(receivedMem.updatedAt, null);
      expect(receivedMem.archivedAt, null);
    },
  );

  test(
    'removeAll',
    () async {
      final memMap = <String, dynamic>{'name': 'test mem name'};
      await memRepository.receive(memMap);
      await memRepository.receive(memMap);

      final removedCount = await memRepository.removeAll();

      expect(removedCount, 2);
    },
  );

  test(
    'selectById',
    () async {
      const memName = 'test mem name';
      final memMap = <String, dynamic>{'name': memName};
      final receivedMem = await memRepository.receive(memMap);

      final selectedMem = await memRepository.selectById(receivedMem.id);

      expect(selectedMem.id, receivedMem.id);
      expect(selectedMem.name, memName);
      expect(selectedMem.createdAt, const TypeMatcher<DateTime>());
      expect(selectedMem.updatedAt, null);
      expect(selectedMem.archivedAt, null);
    },
  );

  test(
    'select',
    () async {
      const memName = 'test mem name';
      final memMap = <String, dynamic>{'name': memName};
      final receivedMem = await memRepository.receive(memMap);
      const memName2 = 'test mem name';
      final memMap2 = <String, dynamic>{'name': memName2};
      final receivedMem2 = await memRepository.receive(memMap2);

      final selectedMemList = await memRepository.select();

      expect(selectedMemList.length, 2);
      expect(
        selectedMemList.map((e) => e.id),
        [receivedMem.id, receivedMem2.id],
      );
    },
  );

  test(
    'updateWhereId',
    () async {
      const memName = 'test mem name';
      final memMap = <String, dynamic>{'name': memName};
      final receivedMem = await memRepository.receive(memMap);

      final map = receivedMem.toMap();
      const updateMemName = 'update mem name';

      final updatedMem = await memRepository.update(
        Mem.fromMap(map..['name'] = updateMemName),
      );

      expect(updatedMem.id, receivedMem.id);
      expect(updatedMem.name, updateMemName);
      expect(updatedMem.createdAt, const TypeMatcher<DateTime>());
      expect(updatedMem.updatedAt, const TypeMatcher<DateTime>());
      expect(
        updatedMem.updatedAt?.millisecondsSinceEpoch,
        greaterThan(updatedMem.createdAt.millisecondsSinceEpoch),
      );
      expect(updatedMem.archivedAt, null);
    },
  );

  test(
    'removeById',
    () async {
      const memName = 'test mem name';
      final memMap = <String, dynamic>{'name': memName};
      final receivedMem = await memRepository.receive(memMap);
      final receivedMem2 = await memRepository.receive(memMap);

      final removeResult = await memRepository.removeById(receivedMem.id);
      expect(removeResult, true);

      final selectedAll = await memRepository.select();
      expect(selectedAll.length, 1);
      expect(selectedAll.map((e) => e.id), [receivedMem2.id]);
    },
  );
}
