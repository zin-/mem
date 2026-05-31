import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/acts/act_service.dart';
import 'package:mem/features/acts/client.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([NotificationClient])
import 'skip_act_by_states_test.mocks.dart';

void main() {
  group('ActEntities.skipActBy', () {
    late AppDatabase db;
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
      mockNotification = MockNotificationClient();
      when(mockNotification.cancelActNotification(any)).thenAnswer((_) async {});
      when(mockNotification.setNotificationAfterInactivity())
          .thenAnswer((_) async {});
      ActsClient(
        actRepository: ActRepository(),
        actQueryService: ActQueryService(),
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

    test('inserts skipped act and refreshes mem latest act', () async {
      final now = DateTime(2024, 10, 11, 12);
      final mem = await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          );

      await container.read(actEntitiesProvider.notifier).skipActBy(mem.id);

      final acts = container.read(actEntitiesProvider);
      expect(acts.single.value.actKind, ActKind.skipped);

      final mems = container.read(memEntitiesProvider);
      expect(mems.single.latestAct?.actKind, ActKind.skipped);

      verify(mockNotification.cancelActNotification(mem.id)).called(1);
      verify(mockNotification.setNotificationAfterInactivity()).called(1);
    });
  });
}
