import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/acts/act_service.dart';
import 'package:mem/features/acts/client.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mockito/mockito.dart';

import 'skip_act_by_states_test.mocks.dart';

void main() {
  group('ActEntities.removeAsync integration', () {
    late AppDatabase db;
    late ActQueryService query;
    late MockNotificationClient mockNotification;
    late ProviderContainer container;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      setOnTest(true);
      db = AppDatabase.memory();
      await Migrator(db).createAll();
      DriftDatabaseAccessor.reset();
      Singleton.reset<ActRepository>();
      ActService.resetSingleton();
      ActsClient.resetSingleton();
      Singleton.override<DriftDatabaseAccessor>(
        DriftDatabaseAccessor.withDatabase(db),
      );
      query = ActQueryService();
      mockNotification = MockNotificationClient();
      when(mockNotification.cancelActNotification(any)).thenAnswer((_) async {});
      when(mockNotification.setNotificationAfterInactivity())
          .thenAnswer((_) async {});
      ActsClient(
        actRepository: ActRepository(),
        actQueryService: query,
        notificationClient: mockNotification,
      );
      container = ProviderContainer();
    });

    tearDown(() async {
      container.dispose();
      await db.close();
      DriftDatabaseAccessor.reset();
      Singleton.reset<ActRepository>();
      ActService.resetSingleton();
      ActsClient.resetSingleton();
      setOnTest(false);
    });

    test('removes act from db and state without self-read', () async {
      final now = DateTime(2024, 10, 11, 12);
      final mem = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );

      await container.read(actEntitiesProvider.notifier).finishActby(mem.id);

      final actId = container.read(actEntitiesProvider).single.id;
      expect(await query.fetchLatestByMemIds(mem.id), isNotNull);

      final removed = await container
          .read(actEntitiesProvider.notifier)
          .removeAsync([actId]);

      expect(removed, hasLength(1));
      expect(removed.single.id, actId);
      expect(container.read(actEntitiesProvider), isEmpty);
      expect(await query.fetchLatestByMemIds(mem.id), isNull);
    });
  });
}
